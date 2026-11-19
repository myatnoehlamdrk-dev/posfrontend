import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Plain-text receipt printed through the browser's own print dialog.
///
/// Browsers cannot open a raw TCP socket to a printer IP, so the only way to
/// reach a Wi-Fi/network thermal printer from the web build is the OS print
/// dialog. Rendering the receipt as plain text (one field per line) keeps the
/// output compatible with generic 80 mm thermal printers that choke on the
/// formatted PDF layout.
Future<void> printPlainTextWindow(Map<String, dynamic> args) async {
  final items = (args['items'] as List?) ?? const [];
  final lines = <String>[
    (args['shopName'] ?? '').toString(),
    'Items: ${items.length}',
    '${args['totalPayable']}',
    'Payment: ${args['paymentMethod']}',
    'Thank you',
  ].where((l) => l.trim().isNotEmpty).toList();

  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: lines
            .map((l) => pw.Text(l, style: const pw.TextStyle(fontSize: 10)))
            .toList(),
      ),
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
    name: 'Receipt',
  );
}