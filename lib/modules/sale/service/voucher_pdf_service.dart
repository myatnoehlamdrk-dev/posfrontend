import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:posfrontend/modules/sale/model/sale_models.dart';

class VoucherPdfService {
  static String _fmt(double value) {
    final v = value.round();
    final digits = v.abs().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return withCommas;
  }

  static Future<void> generateAndPrint({
    required String customerName,
    String? customerPhone,
    required String staffName,
    required String voucherNo,
    required String orderId,
    required DateTime dateTime,
    required List<SaleItem> items,
    required double discountPct,
    required double subtotal,
    required double discountAmt,
    required double totalPayable,
    required String paymentMethod,
    String? notes,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? shopImage,
  }) async {
    final pdf = pw.Document();

    final dateStr = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final h = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final m = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$h:$m $ampm';

    final purple = PdfColor.fromHex('#7C3AED');
    final darkPurple = PdfColor.fromHex('#5B21B6');
    final titleColor = PdfColor.fromHex('#111827');
    final grayColor = PdfColor.fromHex('#6B7280');
    final borderColor = PdfColor.fromHex('#E5E7EB');
    final greenColor = PdfColor.fromHex('#16A34A');
    final lightBg = PdfColor.fromHex('#F9FAFB');
    final lightPurple = PdfColor.fromHex('#F5F0FF');
    final whiteAlpha = PdfColor.fromHex('#B3FFFFFF');

    pw.MemoryImage? shopImg;
    if (shopImage != null && shopImage.isNotEmpty) {
      try {
        final Uint8List imageBytes;
        if (shopImage.startsWith('http')) {
          final uri = Uri.parse(shopImage);
          final request = await HttpClient().getUrl(uri);
          final response = await request.close();
          final bytes = await response.fold<List<int>>(
            <int>[],
            (prev, chunk) => prev..addAll(chunk),
          );
          imageBytes = Uint8List.fromList(bytes);
        } else {
          imageBytes = base64Decode(shopImage);
        }
        shopImg = pw.MemoryImage(imageBytes);
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [purple, darkPurple],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(12),
                topRight: pw.Radius.circular(12),
              ),
            ),
            child: pw.Column(
              children: [
                if (shopImg != null)
                  pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(shopImg, width: 64, height: 64, fit: pw.BoxFit.cover),
                  ),
                if (shopImg != null) pw.SizedBox(height: 10),
                if (shopName != null && shopName.isNotEmpty)
                  pw.Text(shopName, style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                if (shopName != null && shopName.isNotEmpty) pw.SizedBox(height: 4),
                if (shopAddress != null && shopAddress.isNotEmpty)
                  pw.Text(shopAddress, style: pw.TextStyle(color: whiteAlpha, fontSize: 11)),
                if (shopPhone != null && shopPhone.isNotEmpty)
                  pw.Padding(padding: const pw.EdgeInsets.only(top: 2), child: pw.Text(shopPhone, style: pw.TextStyle(color: whiteAlpha, fontSize: 11))),
                pw.SizedBox(height: 10),
                pw.Text('INVOICE', style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                pw.SizedBox(height: 4),
                pw.Text(voucherNo, style: pw.TextStyle(color: whiteAlpha, fontSize: 13)),
              ],
            ),
          ),

          pw.Container(height: 1, color: borderColor),

          // Invoice Info
          pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              children: [
                _infoRow('Voucher ID', voucherNo, titleColor, grayColor),
                pw.SizedBox(height: 6),
                _infoRow('Order ID', orderId, titleColor, grayColor),
                pw.SizedBox(height: 6),
                _infoRow('Date', dateStr, titleColor, grayColor),
                pw.SizedBox(height: 6),
                _infoRow('Time', timeStr, titleColor, grayColor),
                pw.SizedBox(height: 6),
                _infoRow('Staff', staffName, titleColor, grayColor),
              ],
            ),
          ),

          pw.Container(height: 1, color: borderColor),

          // Customer
          pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 36, height: 36,
                  decoration: pw.BoxDecoration(color: lightPurple, borderRadius: pw.BorderRadius.circular(8)),
                  child: pw.Center(child: pw.Text('C', style: pw.TextStyle(color: purple, fontSize: 14, fontWeight: pw.FontWeight.bold))),
                ),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Customer', style: pw.TextStyle(fontSize: 11, color: grayColor)),
                    pw.SizedBox(height: 2),
                    pw.Text(customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: titleColor)),
                    if (customerPhone != null && customerPhone.isNotEmpty)
                      pw.Text(customerPhone, style: pw.TextStyle(fontSize: 12, color: grayColor)),
                  ],
                ),
              ],
            ),
          ),

          pw.Container(height: 1, color: borderColor),

          // Items Header
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 4, child: pw.Text('Item', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: grayColor))),
                pw.Expanded(flex: 1, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: grayColor))),
                pw.Expanded(flex: 2, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: grayColor))),
                pw.Expanded(flex: 2, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: grayColor))),
              ],
            ),
          ),

          // Items
          pw.Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final variant = [
                if (item.size != null && item.size != 'Regular') item.size,
                if (item.color != null && item.color!.isNotEmpty) item.color,
              ].where((e) => e != null && e.isNotEmpty).join(', ');

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                decoration: i < items.length - 1
                    ? pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.5)))
                    : null,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.productName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: titleColor)),
                          if (variant.isNotEmpty)
                            pw.Text(variant, style: pw.TextStyle(fontSize: 11, color: grayColor)),
                        ],
                      ),
                    ),
                    pw.Expanded(flex: 1, child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 13, color: titleColor))),
                    pw.Expanded(flex: 2, child: pw.Text(_fmt(item.unitPrice), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 12, color: titleColor))),
                    pw.Expanded(flex: 2, child: pw.Text(_fmt(item.subtotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: titleColor))),
                  ],
                ),
              );
            }),
          ),

          pw.Container(height: 1, color: borderColor),

          // Summary
          pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              children: [
                _summaryRow('Subtotal', subtotal, titleColor, grayColor),
                if (discountPct > 0) ...[
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Discount ($discountPct%)', style: pw.TextStyle(fontSize: 13, color: grayColor)),
                      pw.Text('-${_fmt(discountAmt)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#EF4444'))),
                    ],
                  ),
                ],
                pw.SizedBox(height: 10),
                pw.Container(height: 1, color: borderColor),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Payable', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: titleColor)),
                    pw.Text(_fmt(totalPayable), style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: purple)),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: pw.BoxDecoration(color: lightPurple, borderRadius: pw.BorderRadius.circular(8)),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Payment Method', style: pw.TextStyle(fontSize: 13, color: grayColor)),
                      pw.Text(paymentMethod, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: purple)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notes
          if (notes != null && notes.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FEF9C3'), borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Notes', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#92400E'))),
                    pw.SizedBox(height: 4),
                    pw.Text(notes, style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#78350F'))),
                  ],
                ),
              ),
            ),

          // Footer
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(color: lightBg, borderRadius: const pw.BorderRadius.only(bottomLeft: pw.Radius.circular(12), bottomRight: pw.Radius.circular(12))),
            child: pw.Column(
              children: [
                pw.Text('Thank you for your purchase!', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: titleColor)),
                pw.SizedBox(height: 4),
                pw.Text('Total Items: ${items.length}', style: pw.TextStyle(fontSize: 12, color: grayColor)),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Voucher_$voucherNo',
    );
  }

  static pw.Widget _infoRow(String label, String value, PdfColor titleColor, PdfColor grayColor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 13, color: grayColor)),
        pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: titleColor)),
      ],
    );
  }

  static pw.Widget _summaryRow(String label, double amount, PdfColor titleColor, PdfColor grayColor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 13, color: grayColor)),
        pw.Text(_fmt(amount), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: titleColor)),
      ],
    );
  }
}
