import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<bool> saveReportBytes(
  Uint8List bytes, {
  required String filename,
  required String mimeType,
}) async {
  try {
    final blob = web.Blob(
      <JSAny>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = filename
      ..style.display = 'none';

    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    // Give the browser a moment to start the download before releasing the URL.
    Future<void>.delayed(
      const Duration(seconds: 1),
      () => web.URL.revokeObjectURL(url),
    );
    return true;
  } catch (_) {
    return false;
  }
}
