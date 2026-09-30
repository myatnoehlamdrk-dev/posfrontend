import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:posfrontend/shared/l10n/app_language.dart';

/// Regular and bold font bytes, for building a [pw.ThemeData] inside an isolate.
class PdfFontBytes {
  const PdfFontBytes(this.regular, this.bold);

  final Uint8List regular;
  final Uint8List bold;
}

/// Supplies the PDF's fonts per language.
///
/// The receipt writer runs in an [Isolate], and a `pw.Font` holds native
/// memory that cannot cross an isolate boundary -- only the bytes can. So the
/// bytes are read once in the main isolate (where [rootBundle] works) and
/// carried into the isolate, which builds the `pw.Font` from them.
///
/// English keeps the PDF package's built-in Helvetica. That is deliberate: the
/// receipts are in Latin script, Helvetica needs no file, and it renders
/// Western digits more compactly. The other three languages have no built-in
/// coverage at all -- Helvetica would emit empty boxes for Burmese, Thai and
/// Japanese -- and a PDF cannot fall back to a system font the way the Flutter
/// UI can, so each gets its bundled Noto face. Those faces also carry Latin
/// glyphs, so one font covers the script, the numerals and any untranslated
/// English in the same run.
class PdfFonts {
  const PdfFonts._();

  static const Map<AppLanguage, (String regular, String bold)> _assets = {
    AppLanguage.myanmar: (
      'assets/fonts/NotoSansMyanmar-Regular.ttf',
      'assets/fonts/NotoSansMyanmar-Bold.ttf',
    ),
    AppLanguage.thai: (
      'assets/fonts/NotoSansThai-Regular.ttf',
      'assets/fonts/NotoSansThai-Bold.ttf',
    ),
    AppLanguage.japanese: (
      'assets/fonts/NotoSansJP-Regular.ttf',
      'assets/fonts/NotoSansJP-Bold.ttf',
    ),
  };

  /// A language is not translated but is still rendered in a script the
  /// built-in font cannot draw.
  static bool _needsBundledFont(AppLanguage language) =>
      _assets.containsKey(language);

  static final Map<AppLanguage, PdfFontBytes> _cache = {};

  /// Font bytes for [language], or `null` when the built-in font will do.
  ///
  /// Cached per language: the Japanese faces are ~10 MB together and a receipt
  /// is built on every sale, so re-reading them per print would be wasteful.
  static Future<PdfFontBytes?> forLanguage(AppLanguage language) async {
    if (!_needsBundledFont(language)) return null;
    final cached = _cache[language];
    if (cached != null) return cached;

    final (regular, bold) = _assets[language]!;
    final loaded = PdfFontBytes(await _read(regular), await _read(bold));
    _cache[language] = loaded;
    return loaded;
  }

  static Future<Uint8List> _read(String asset) async {
    final data = await rootBundle.load(asset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Font bytes for a document.
  ///
  /// `ByteData` rather than `Uint8List` because that is what
  /// [pw.Font.ttf] takes.
  static pw.ThemeData theme(PdfFontBytes? bytes) {
    if (bytes == null) {
      return pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
    }
    return pw.ThemeData.withFont(
      base: pw.Font.ttf(ByteData.sublistView(bytes.regular)),
      bold: pw.Font.ttf(ByteData.sublistView(bytes.bold)),
    );
  }
}
