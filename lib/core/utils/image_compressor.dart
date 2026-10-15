import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Result of [compressImage]: the (possibly) shrunk bytes plus a file name
/// whose extension matches the actual encoding, so the upload layer can set
/// the multipart content type correctly.
///
/// [previewFile] holds the same compressed bytes on a temp file so a screen
/// can show the local preview without decoding the original 12MP photo. It is
/// null on web (where previews use the picked file's blob URL) and whenever
/// [compressImage] is called without `writePreviewFile`.
class CompressedImage {
  final Uint8List bytes;
  final String fileName;
  final File? previewFile;

  const CompressedImage({
    required this.bytes,
    required this.fileName,
    this.previewFile,
  });
}

/// Downscale + re-encode a picked photo before it is uploaded.
///
/// Tills pick photos straight from the camera/gallery, which are typically
/// 12MP / 4-8MB. Sending those raw is slow on a shop's mobile connection and
/// the host (ImgBB) stores the original forever — so every product grid then
/// downloads full resolution on first view. This trims to [maxEdge] pixels on
/// the longest side at [quality] JPEG, which is roughly 150-300KB for a
/// product photo without a visible quality loss at POS-sized displays.
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
  int maxEdge = 1600,
  int quality = 80,
  bool writePreviewFile = false,
}) async {
  final raw = await file.readAsBytes();
  final originalName = _uploadName(file);
  CompressedImage result;
  try {
    final out = await compute(_compressBytes, _CompressRequest(raw, maxEdge, quality));
    result = CompressedImage(
      bytes: out.bytes,
      fileName: _nameFor(originalName, out.isPng),
    );
  } catch (_) {
    // Undecodable format or a failure in the pipeline — upload the original
    // rather than blocking the user.
    result = CompressedImage(bytes: raw, fileName: originalName);
  }
  if (!writePreviewFile || kIsWeb) return result;
  return CompressedImage(
    bytes: result.bytes,
    fileName: result.fileName,
    previewFile: _writePreview(result.bytes, result.fileName),
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
  final bool isPng;

  const _CompressResult(this.bytes, this.isPng);
}

_CompressResult _compressBytes(_CompressRequest request) {
  final raw = request.bytes;
  // Animated GIFs are passed through untouched: re-encoding would drop the
  // animation, and decoding them first would just burn CPU for nothing.
  if (_isGif(raw)) {
    return _CompressResult(raw, false);
  }

  final decoded = img.decodeImage(raw);
  if (decoded == null) {
    throw const FormatException('Unsupported or corrupt image');
  }

  final isPng = _isPng(raw);

  // Already small in both dimensions and bytes — nothing to gain, and
  // re-encoding would only burn CPU and lose a little quality for nothing.
  final fitsCanvas = decoded.width <= request.maxEdge &&
      decoded.height <= request.maxEdge;
  if (fitsCanvas && raw.length <= _skipThresholdBytes) {
    return _CompressResult(raw, isPng);
  }

  final resized = fitsCanvas
      ? decoded
      : decoded.width >= decoded.height
      ? img.copyResize(
          decoded,
          width: request.maxEdge,
          interpolation: img.Interpolation.average,
        )
      : img.copyResize(
          decoded,
          height: request.maxEdge,
          interpolation: img.Interpolation.average,
        );

  if (isPng) {
    return _CompressResult(img.encodePng(resized), true);
  }
  return _CompressResult(img.encodeJpg(resized, quality: request.quality), false);
}

/// Files at or below this are left alone even if they decode to a large
/// canvas — they are already cheap to download and store.
const int _skipThresholdBytes = 200 * 1024;

/// A picked file's name is only as trustworthy as the separators in its path:
/// a mixed-separator path would otherwise put a '/' into the multipart
/// filename and confuse the upload host.
String _uploadName(XFile file) {
  final base = file.name.replaceAll('\\', '/').split('/').last;
  return base.isEmpty ? 'upload.jpg' : base;
}

String _nameFor(String originalName, bool isPng) {
  final dot = originalName.lastIndexOf('.');
  final base = dot > 0 ? originalName.substring(0, dot) : originalName;
  return '$base.${isPng ? 'png' : 'jpg'}';
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
