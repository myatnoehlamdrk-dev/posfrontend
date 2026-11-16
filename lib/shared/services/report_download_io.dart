import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> saveReportBytes(
  Uint8List bytes, {
  required String filename,
  required String mimeType,
}) async {
  try {
    final directory = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);

    // The share sheet is the reliable way to hand a file to the user on
    // Android/iOS; on desktop this is a no-op and the file is opened instead.
    try {
      if (await Printing.sharePdf(bytes: bytes, filename: filename)) {
        return true;
      }
    } catch (_) {
      // Fall through to opening the written file.
    }

    return await launchUrl(file.uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
