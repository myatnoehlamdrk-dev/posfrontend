import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Result of [compressImage]: the (possibly) shrunk bytes plus a file name
/// whose extension matches the actual encoding, so the upload layer can set
/// the multipart content type correctly.
///
/// [previewFile] holds the same compressed bytes as a temp file so a screen
/// can show the local preview without decoding the original 12MP photo. It is
/// null on web (where previews use the picked file's blob URL) and whenever
/// [compressImage] is called without `writePreviewFile`.
class CompressedImage {
  final Uint8List bytes;
  final String fileName;
  final File? previewFile;

  /// True when the file went back out exactly as it came in, but too large to
  /// be worth that: nothing could decode it (HEIC and similar), so the budget
  /// was never applied.
  ///
  /// The upload still happens — losing a photo over its file size is a worse
  /// trade than a slow one — but callers use this to tell the user what they
  /// are about to wait for.
  final bool oversized;

  const CompressedImage({
    required this.bytes,
    required this.fileName,
    this.previewFile,
    this.oversized = false,
  });
}

/// Downscale + re-encode a picked photo before it is uploaded.
///
/// Tills pick photos straight from the camera/gallery, which are typically
/// 12MP / 4-8MB. Sending those raw is slow on a shop's mobile connection and
/// the host (ImgBB) stores the original forever — so every product grid then
/// downloads full resolution on first view.
///
/// What the pipeline guarantees, in order of what a user actually sees:
///
///  - **The result is never bigger than the input.** A re-encode that did not
///    beat the original byte for byte is thrown away in favor of the
///    original; "compression" must not be able to make a file grow.
///  - **JPEG output lands under ~200KB** by stepping quality down (starting
///    at [quality], then 70, then 60) and, only if that is not enough,
///    the canvas down (960px, then 720px on the longest side).
///  - **Photos handed out as PNG become JPEG.** Some sites serve a photo as
///    a PNG; kept losslessly it is still megabytes at any sane pixel size,
///    while the same pixels at JPEG q80 are a couple hundred KB.
///  - **Transparency survives.** Art that actually uses its alpha channel
///    stays PNG — JPEG has nowhere to keep alpha — and is trimmed through
///    the same budget ladder instead.
///  - **Portrait photos stay upright.** A phone records "turn me 90°" as an
///    EXIF flag, which the re-encode below would discard; so the rotation is
///    applied to the pixels first.
///
/// The decode/resize runs in an isolate via [compute] so the UI never janks.
/// Work is skipped when the input is already small enough, and any input we
/// cannot decode (HEIC, corrupt files) is returned untouched rather than
/// failing the upload.
///
/// Animated GIFs are passed through untouched: re-encoding them would drop
/// the animation, and they are rare/small enough not to be worth optimizing.
Future<CompressedImage> compressImage(
  XFile file, {
  int maxEdge = 1280,
  int quality = 80,
  bool writePreviewFile = false,
}) async {
  final raw = await file.readAsBytes();
  final originalName = _uploadName(file);
  CompressedImage result;
  try {
    final out = await compute(
      _compressBytes,
      _CompressRequest(raw, maxEdge, quality),
    );
    result = CompressedImage(
      bytes: out.bytes,
      fileName: _nameFor(originalName, out.ext),
    );
  } catch (_) {
    // Undecodable format or a failure in the pipeline — upload the original
    // rather than blocking the user. Flagged when that original is also over
    // budget, so a multi-megabyte upload can be announced instead of passing
    // for a normal one.
    result = CompressedImage(
      bytes: raw,
      fileName: originalName,
      oversized: raw.length > _sizeBudgetBytes,
    );
  }
  if (!writePreviewFile || kIsWeb) return result;
  return CompressedImage(
    bytes: result.bytes,
    fileName: result.fileName,
    previewFile: _writePreview(result.bytes, result.fileName),
    oversized: result.oversized,
  );
}

/// Best-effort: a preview that cannot be written is not worth failing the
/// upload over, so the caller simply falls back to the picked file's path.
File? _writePreview(Uint8List bytes, String fileName) {
  try {
    final dir = Directory.systemTemp;
    _pruneStalePreviews(dir);
    final dot = fileName.lastIndexOf('.');
    final ext = dot > 0 ? fileName.substring(dot) : '.jpg';
    final file = File(
      '${dir.path}/pos_preview_${DateTime.now().microsecondsSinceEpoch}$ext',
    );
    file.writeAsBytesSync(bytes, flush: true);
    return file;
  } catch (_) {
    return null;
  }
}

/// Temp previews pile up one per upload, so sweep the old ones. Best-effort:
/// a failed sweep is not worth failing an upload over.
void _pruneStalePreviews(Directory dir) {
  final cutoff = DateTime.now().subtract(const Duration(hours: 1));
  for (final entry in dir.listSync().whereType<File>()) {
    if (!entry.uri.pathSegments.last.startsWith('pos_preview_')) continue;
    if (entry.lastModifiedSync().isBefore(cutoff)) {
      try {
        entry.deleteSync();
      } catch (_) {
        // Best-effort cleanup; the OS reaps temp eventually.
      }
    }
  }
}

class _CompressRequest {
  final Uint8List bytes;
  final int maxEdge;
  final int quality;

  const _CompressRequest(this.bytes, this.maxEdge, this.quality);
}

class _CompressResult {
  final Uint8List bytes;

  /// Extension of the encoding [bytes] actually are: `'jpg'`, `'png'`,
  /// `'gif'`, `'webp'`. Passthrough paths sniff the original bytes so an
  /// untouched file keeps the encoding it arrived with.
  final String ext;

  const _CompressResult(this.bytes, this.ext);
}

_CompressResult _compressBytes(_CompressRequest request) {
  final raw = request.bytes;
  // Animated GIFs are passed through untouched: re-encoding would drop the
  // animation, and decoding them first would just burn CPU for nothing.
  if (_isGif(raw)) {
    return _CompressResult(raw, 'gif');
  }

  final decoded = img.decodeImage(raw);
  if (decoded == null) {
    throw const FormatException('Unsupported or corrupt image');
  }

  // A camera stores "turn me 90°" as an EXIF flag, not as rotated pixels, and
  // re-encoding drops that flag on the floor. Everything below therefore has
  // to turn the pixels itself first, or every portrait photo taken on a phone
  // comes back sideways. Checked before it is called because `bakeOrientation`
  // copies the whole canvas even when there is nothing to turn — on a 12MP
  // photo that is the most expensive thing this function could do for no
  // reason. The passthrough path keeps the original bytes — flag included —
  // and needs no such care.
  final ifd = decoded.exif.imageIfd;
  final oriented = ifd.hasOrientation && ifd.orientation != 1
      ? img.bakeOrientation(decoded)
      : decoded;

  // Already small in both dimensions and bytes — nothing to gain, and
  // re-encoding would only burn CPU and lose a little quality for nothing.
  final fitsCanvas =
      oriented.width <= request.maxEdge && oriented.height <= request.maxEdge;
  if (fitsCanvas && raw.length <= _sizeBudgetBytes) {
    return _CompressResult(raw, _sniffExt(raw));
  }

  final canvas = fitsCanvas
      ? oriented
      : _resizeLongest(oriented, request.maxEdge);

  // Fully opaque images go to JPEG — including photos served as PNG, which
  // are the worst offenders: losslessly they never fit the budget no matter
  // how many pixels come off. Art that really uses transparency stays PNG,
  // because JPEG's encoder would blend the transparent parts onto white and
  // hand someone's logo a white box.
  final transparent = _hasTransparency(oriented);
  final out = transparent
      ? _encodePngToBudget(canvas)
      : _encodeJpegToBudget(canvas, request);

  // Never grow: if the re-encode did not beat the original byte for byte,
  // the original is the strictly better upload — fewer bytes, at least as
  // much detail. This is the guarantee that "compression" cannot make a
  // hosted image bigger than what was picked.
  if (out.length >= raw.length) {
    return _CompressResult(raw, _sniffExt(raw));
  }

  return _CompressResult(out, transparent ? 'png' : 'jpg');
}

/// Longest-side resize, used both to fit the picked image into the canvas
/// and to step it down while hunting for the byte budget.
img.Image _resizeLongest(img.Image source, int edge) =>
    source.width >= source.height
    ? img.copyResize(
        source,
        width: edge,
        interpolation: img.Interpolation.average,
      )
    : img.copyResize(
        source,
        height: edge,
        interpolation: img.Interpolation.average,
      );

/// Canvases worth encoding while hunting for the byte budget: the one we
/// have, then successively smaller longest-side steps — never an upscale.
List<img.Image> _canvasLadder(img.Image canvas) {
  final ladder = <img.Image>[canvas];
  var current = canvas;
  for (final edge in _budgetEdges) {
    if (math.max(current.width, current.height) <= edge) continue;
    current = _resizeLongest(current, edge);
    ladder.add(current);
  }
  return ladder;
}

/// The longest-side steps tried when the file still will not fit the budget,
/// starting from a canvas that tops out at 1280px.
const List<int> _budgetEdges = [960, 720];

/// JPEG qualities in try-order: the caller's starting quality first, then
/// the two fallbacks. A set literal keeps insertion order and de-duplicates,
/// so a call site passing 70 starts at 70 instead of repeating it.
Set<int> _jpegQualities(int start) => <int>{start, 70, 60};

Uint8List _encodeJpegToBudget(img.Image canvas, _CompressRequest request) {
  Uint8List? best;
  for (final candidate in _canvasLadder(canvas)) {
    for (final quality in _jpegQualities(request.quality)) {
      // yuv420 is the chroma subsampling every camera and browser uses; at
      // these sizes the gap from yuv444 is invisible and the bytes are
      // noticeably fewer.
      final out = img.encodeJpg(
        candidate,
        quality: quality,
        chroma: img.JpegChroma.yuv420,
      );
      if (best == null || out.length < best.length) best = out;
      if (out.length <= _sizeBudgetBytes) return out;
    }
  }
  // Ladder exhausted: hand back the smallest thing we produced. The caller's
  // never-grow guard still stands between this and a bigger upload.
  return best!;
}

Uint8List _encodePngToBudget(img.Image canvas) {
  Uint8List? best;
  for (final candidate in _canvasLadder(canvas)) {
    final out = img.encodePng(candidate);
    if (best == null || out.length < best.length) best = out;
    if (out.length <= _sizeBudgetBytes) return out;
  }
  return best!;
}

/// Whether any pixel is not fully opaque.
///
/// Only images carrying an alpha channel can answer yes, and those are
/// overwhelmingly logos and icons that give up at the first transparent
/// pixel. A fully opaque RGBA image pays a full scan — the price of never
/// putting a white box behind someone's artwork.
bool _hasTransparency(img.Image image) {
  if (!image.hasAlpha) return false;
  for (final pixel in image) {
    if (pixel.aNormalized < 1.0) return true;
  }
  return false;
}

/// The extension matching the encoding these bytes actually are. Used on
/// every passthrough path: the upload layer reads the name to pick the
/// multipart content type, so naming untouched bytes `.jpg` when they are
/// PNG or WebP would mislabel the upload.
String _sniffExt(Uint8List bytes) {
  if (_isPng(bytes)) return 'png';
  if (_isGif(bytes)) return 'gif';
  if (_isWebp(bytes)) return 'webp';
  return 'jpg';
}

/// Files at or below this are left alone even if they decode to a large
/// canvas — they are already cheap to download and store. It is also the
/// size every re-encode hunts to land under, so the whole file follows one
/// rule: a hosted image is either untouched-because-tiny or at most ~200KB.
const int _sizeBudgetBytes = 200 * 1024;

/// A picked file's name is only as trustworthy as the separators in its path:
/// a mixed-separator path would otherwise put a '/' into the multipart
/// filename and confuse the upload host.
String _uploadName(XFile file) {
  final base = file.name.replaceAll('\\', '/').split('/').last;
  return base.isEmpty ? 'upload.jpg' : base;
}

/// The original name with its extension replaced by [ext], so a JPEG
/// re-encoded from `photo.PNG` uploads as `photo.jpg` and the content type
/// the upload layer derives from the name matches the bytes.
String _nameFor(String originalName, String ext) {
  final dot = originalName.lastIndexOf('.');
  final base = dot > 0 ? originalName.substring(0, dot) : originalName;
  return '$base.$ext';
}

bool _isPng(Uint8List bytes) =>
    bytes.length > 8 &&
    bytes[0] == 0x89 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x4E &&
    bytes[3] == 0x47;

bool _isGif(Uint8List bytes) =>
    bytes.length > 4 &&
    bytes[0] == 0x47 &&
    bytes[1] == 0x49 &&
    bytes[2] == 0x46 &&
    bytes[3] == 0x38;

bool _isWebp(Uint8List bytes) =>
    bytes.length > 12 &&
    bytes[0] == 0x52 &&
    bytes[1] == 0x49 &&
    bytes[2] == 0x46 &&
    bytes[3] == 0x46 && // RIFF
    bytes[8] == 0x57 &&
    bytes[9] == 0x45 &&
    bytes[10] == 0x42 &&
    bytes[11] == 0x50; // WEBP
