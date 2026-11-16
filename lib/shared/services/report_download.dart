import 'dart:typed_data';

import 'report_download_stub.dart'
    if (dart.library.js_interop) 'report_download_web.dart'
    if (dart.library.io) 'report_download_io.dart' as impl;

/// Hands a generated report to the user.
///
/// Web triggers a normal browser download, native targets write the file and
/// then hand it to the OS share/open flow. Returns false when the platform
/// could not start the download, so the caller can surface an error instead of
/// failing silently.
class ReportDownload {
  ReportDownload._();

  static Future<bool> save(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) {
    return impl.saveReportBytes(
      bytes,
      filename: filename,
      mimeType: mimeType,
    );
  }
}
