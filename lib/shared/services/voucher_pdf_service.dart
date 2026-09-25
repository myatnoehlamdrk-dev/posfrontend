import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';

String _fmt(double value) => value.withCommas();

pw.Widget _infoRow(
  String label,
  String value,
  PdfColor titleColor,
  PdfColor grayColor,
) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 13, color: grayColor)),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: titleColor,
        ),
      ),
    ],
  );
}

pw.Widget _summaryRow(
  String label,
  double amount,
  PdfColor titleColor,
  PdfColor grayColor,
) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 13, color: grayColor)),
      pw.Text(
        _fmt(amount),
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: titleColor,
        ),
      ),
    ],
  );
}

pw.Widget _receiptInfoRow(
  String label,
  String value,
  PdfColor titleColor,
  PdfColor grayColor,
) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 8, color: grayColor)),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: titleColor,
        ),
      ),
    ],
  );
}

pw.Widget _receiptSummaryRow(
  String label,
  String value,
  PdfColor valueColor,
  PdfColor grayColor,
) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 8, color: grayColor)),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: valueColor,
        ),
      ),
    ],
  );
}

Future<Uint8List?> _toMonochromePng(Uint8List? bytes) async {
  if (bytes == null || bytes.isEmpty) return null;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width;
    final height = image.height;
    final rgba = await image.toByteData();
    if (rgba == null) return bytes;
    final out = Uint8List(width * height * 4);
    for (int i = 0; i < width * height; i++) {
      final o = i * 4;
      final a = rgba.getUint8(o + 3);
      final lum =
          (rgba.getUint8(o) * 299 +
              rgba.getUint8(o + 1) * 587 +
              rgba.getUint8(o + 2) * 114) ~/
          1000;
      final v = (a >= 128 && lum <= 140) ? 0 : 255;
      out[o] = v;
      out[o + 1] = v;
      out[o + 2] = v;
      out[o + 3] = 255;
    }
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      out,
      width,
      height,
      ui.PixelFormat.bgra8888,
      c.complete,
    );
    final mono = await c.future;
    final png = await mono.toByteData(format: ui.ImageByteFormat.png);
    return png?.buffer.asUint8List() ?? bytes;
  } catch (_) {
    return bytes;
  }
}

class PdfBuildParams {
  final String customerName;
  final String? customerPhone;
  final String staffName;
  final String voucherNo;
  final String orderId;
  final DateTime dateTime;
  final List<SaleItem> items;
  final double discountPct;
  final double subtotal;
  final double discountAmt;
  final double totalPayable;
  final String paymentMethod;
  final String? notes;
  final String? shopName;
  final String? shopAddress;
  final String? shopPhone;
  final Uint8List? shopImageBytes;
  final double paperWidthMm;
  final String? customerLocation;

  PdfBuildParams({
    required this.customerName,
    this.customerPhone,
    required this.staffName,
    required this.voucherNo,
    required this.orderId,
    required this.dateTime,
    required this.items,
    required this.discountPct,
    required this.subtotal,
    required this.discountAmt,
    required this.totalPayable,
    required this.paymentMethod,
    this.notes,
    this.shopName,
    this.shopAddress,
    this.shopPhone,
    this.shopImageBytes,
    this.paperWidthMm = 56.7,
    this.customerLocation,
  });
}

Future<Uint8List> _buildA4PdfBytes(PdfBuildParams params) async {
  final pdf = pw.Document();
  final dateStr = params.dateTime.toShortDate();
  final timeStr = params.dateTime
      .toFormattedDateTime()
      .split(' ')
      .skip(1)
      .join(' ');

  final purple = PdfColor.fromHex('#7C3AED');
  final darkPurple = PdfColor.fromHex('#5B21B6');
  final titleColor = PdfColor.fromHex('#111827');
  final grayColor = PdfColor.fromHex('#6B7280');
  final borderColor = PdfColor.fromHex('#E5E7EB');
  final lightBg = PdfColor.fromHex('#F9FAFB');
  final lightPurple = PdfColor.fromHex('#F5F0FF');
  final whiteAlpha = PdfColor.fromHex('#B3FFFFFF');

  pw.MemoryImage? shopImg;
  if (params.shopImageBytes != null) {
    shopImg = pw.MemoryImage(params.shopImageBytes!);
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
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
                  child: pw.Image(
                    shopImg,
                    width: 64,
                    height: 64,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              if (shopImg != null) pw.SizedBox(height: 10),
              if (params.shopName != null && params.shopName!.isNotEmpty)
                pw.Text(
                  params.shopName!,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              if (params.shopName != null && params.shopName!.isNotEmpty)
                pw.SizedBox(height: 4),
              if (params.shopAddress != null && params.shopAddress!.isNotEmpty)
                pw.Text(
                  params.shopAddress!,
                  style: pw.TextStyle(color: whiteAlpha, fontSize: 11),
                ),
              if (params.shopPhone != null && params.shopPhone!.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    params.shopPhone!,
                    style: pw.TextStyle(color: whiteAlpha, fontSize: 11),
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                params.voucherNo,
                style: pw.TextStyle(color: whiteAlpha, fontSize: 13),
              ),
            ],
          ),
        ),

        pw.Container(height: 1, color: borderColor),

        pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            children: [
              _infoRow('Voucher ID', params.voucherNo, titleColor, grayColor),
              pw.SizedBox(height: 6),
              _infoRow('Order ID', params.orderId, titleColor, grayColor),
              pw.SizedBox(height: 6),
              _infoRow('Date', dateStr, titleColor, grayColor),
              pw.SizedBox(height: 6),
              _infoRow('Time', timeStr, titleColor, grayColor),
              pw.SizedBox(height: 6),
              _infoRow('Staff', params.staffName, titleColor, grayColor),
            ],
          ),
        ),

        pw.Container(height: 1, color: borderColor),

        pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Row(
            children: [
              pw.Container(
                width: 36,
                height: 36,
                decoration: pw.BoxDecoration(
                  color: lightPurple,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'C',
                    style: pw.TextStyle(
                      color: purple,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Customer',
                    style: pw.TextStyle(fontSize: 11, color: grayColor),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    params.customerName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  if (params.customerPhone != null &&
                      params.customerPhone!.isNotEmpty)
                    pw.Text(
                      params.customerPhone!,
                      style: pw.TextStyle(fontSize: 12, color: grayColor),
                    ),
                ],
              ),
            ],
          ),
        ),

        pw.Container(height: 1, color: borderColor),

        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  'Item',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: grayColor,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Qty',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: grayColor,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Price',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: grayColor,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Total',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: grayColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        pw.Column(
          children: List.generate(params.items.length, (i) {
            final item = params.items[i];
            final variant = [
              if (item.size != null && item.size != 'Regular') item.size,
              if (item.color?.isNotEmpty == true) item.color,
            ].where((e) => e != null && e.isNotEmpty).join(', ');

            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 20,
              ),
              decoration: i < params.items.length - 1
                  ? pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: borderColor, width: 0.5),
                      ),
                    )
                  : null,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.productName,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        if (variant.isNotEmpty)
                          pw.Text(
                            variant,
                            style: pw.TextStyle(fontSize: 11, color: grayColor),
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '${item.quantity}',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 13, color: titleColor),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      _fmt(item.unitPrice),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontSize: 12, color: titleColor),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      _fmt(item.subtotal),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        pw.Container(height: 1, color: borderColor),

        pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            children: [
              _summaryRow('Subtotal', params.subtotal, titleColor, grayColor),
              if (params.discountPct > 0) ...[
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Discount (${params.discountPct}%)',
                      style: pw.TextStyle(fontSize: 13, color: grayColor),
                    ),
                    pw.Text(
                      '-${_fmt(params.discountAmt)}',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#EF4444'),
                      ),
                    ),
                  ],
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Container(height: 1, color: borderColor),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Payable',
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  pw.Text(
                    _fmt(params.totalPayable),
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                      color: purple,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: lightPurple,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Payment Method',
                      style: pw.TextStyle(fontSize: 13, color: grayColor),
                    ),
                    pw.Text(
                      params.paymentMethod,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (params.notes != null && params.notes!.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FEF9C3'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Notes',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#92400E'),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    params.notes!,
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColor.fromHex('#78350F'),
                    ),
                  ),
                ],
              ),
            ),
          ),

        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: lightBg,
            borderRadius: const pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(12),
              bottomRight: pw.Radius.circular(12),
            ),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Thank you for your purchase!',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: titleColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Total Items: ${params.items.length}',
                style: pw.TextStyle(fontSize: 12, color: grayColor),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  return await pdf.save();
}

Future<Uint8List> _buildReceiptPdfBytes(PdfBuildParams params) async {
  final pdf = pw.Document();
  final dateStr = params.dateTime.toShortDate();
  final timeStr = params.dateTime
      .toFormattedDateTime()
      .split(' ')
      .skip(1)
      .join(' ');
  final purple = PdfColor.fromHex('#7C3AED');
  final grayColor = PdfColor.fromHex('#6B7280');
  final titleColor = PdfColor.fromHex('#111827');
  final borderColor = PdfColor.fromHex('#E5E7EB');

  pw.MemoryImage? shopImg;
  if (params.shopImageBytes != null) {
    shopImg = pw.MemoryImage(params.shopImageBytes!);
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat(
        params.paperWidthMm * PdfPageFormat.mm,
        297 * PdfPageFormat.mm,
      ),
      margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      theme: pw.ThemeData.withFont(
        base: pw.Font.courier(),
        bold: pw.Font.courierBold(),
      ),
      build: (context) => [
        if (shopImg != null)
          pw.Center(
            child: pw.ClipRRect(
              horizontalRadius: 4,
              verticalRadius: 4,
              child: pw.Image(
                shopImg,
                width: 16 * PdfPageFormat.mm,
                height: 16 * PdfPageFormat.mm,
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        if (shopImg != null) pw.SizedBox(height: 4),
        if (params.shopName != null && params.shopName!.isNotEmpty)
          _receiptInfoRow('Shop name', params.shopName!, titleColor, grayColor),
        if (params.shopAddress != null && params.shopAddress!.isNotEmpty)
          _receiptInfoRow(
            'Location',
            params.shopAddress!,
            titleColor,
            grayColor,
          ),
        if (params.shopPhone != null && params.shopPhone!.isNotEmpty)
          _receiptInfoRow(
            'Shop Contact',
            params.shopPhone!,
            titleColor,
            grayColor,
          ),
        _receiptInfoRow('Invoice no', params.voucherNo, titleColor, grayColor),
        pw.SizedBox(height: 4),
        pw.Container(height: 0.5, color: borderColor),
        pw.SizedBox(height: 4),
        _receiptInfoRow('Date', dateStr, titleColor, grayColor),
        _receiptInfoRow('Time', timeStr, titleColor, grayColor),
        _receiptInfoRow('Customer', params.customerName, titleColor, grayColor),
        if (params.customerPhone != null && params.customerPhone!.isNotEmpty)
          _receiptInfoRow(
            'Phone',
            params.customerPhone!,
            titleColor,
            grayColor,
          ),
        if (params.customerLocation != null &&
            params.customerLocation!.isNotEmpty)
          _receiptInfoRow(
            'Location',
            params.customerLocation!,
            titleColor,
            grayColor,
          ),
        pw.SizedBox(height: 4),
        pw.Container(height: 0.5, color: borderColor),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                'Item',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: grayColor,
                ),
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                'Qty',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: grayColor,
                ),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Total',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: grayColor,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        ...List.generate(params.items.length, (i) {
          final item = params.items[i];
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      item.productName,
                      style: pw.TextStyle(fontSize: 8, color: titleColor),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '${item.quantity}',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 8, color: titleColor),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      _fmt(item.subtotal),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontSize: 8, color: titleColor),
                    ),
                  ),
                ],
              ),
              if (i < params.items.length - 1) pw.SizedBox(height: 2),
            ],
          );
        }),
        pw.SizedBox(height: 4),
        pw.Container(height: 0.5, color: borderColor),
        pw.SizedBox(height: 4),
        _receiptSummaryRow(
          'Subtotal',
          _fmt(params.subtotal),
          titleColor,
          grayColor,
        ),
        if (params.discountPct > 0)
          _receiptSummaryRow(
            'Discount (${params.discountPct}%)',
            '-${_fmt(params.discountAmt)}',
            PdfColor.fromHex('#EF4444'),
            grayColor,
          ),
        pw.SizedBox(height: 2),
        pw.Container(height: 0.5, color: borderColor),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: titleColor,
              ),
            ),
            pw.Text(
              _fmt(params.totalPayable),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: purple,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Payment',
              style: pw.TextStyle(fontSize: 8, color: grayColor),
            ),
            pw.Text(
              params.paymentMethod,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
        if (params.notes != null && params.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Notes: ${params.notes}',
            style: pw.TextStyle(fontSize: 7, color: grayColor),
          ),
        ],
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            'Thank you!',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: titleColor,
            ),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(
            'Items: ${params.items.length}',
            style: pw.TextStyle(fontSize: 7, color: grayColor),
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    ),
  );

  return await pdf.save();
}

class VoucherPdfService {
  static Future<Uint8List?> _fetchShopImage(String? shopImage) async {
    if (shopImage == null || shopImage.isEmpty) return null;
    try {
      final resolved = resolveMediaUrl(shopImage);
      if (resolved == null || resolved.isEmpty) return null;
      if (resolved.startsWith('http')) {
        final uri = Uri.parse(resolved);
        final request = await HttpClient().getUrl(uri);
        final response = await request.close();
        final bytes = await response.fold<List<int>>(
          <int>[],
          (prev, chunk) => prev..addAll(chunk),
        );
        return Uint8List.fromList(bytes);
      } else {
        return base64Decode(shopImage);
      }
    } catch (_) {
      return null;
    }
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
    final imageBytes = await _fetchShopImage(shopImage);

    final params = PdfBuildParams(
      customerName: customerName,
      customerPhone: customerPhone,
      staffName: staffName,
      voucherNo: voucherNo,
      orderId: orderId,
      dateTime: dateTime,
      items: items,
      discountPct: discountPct,
      subtotal: subtotal,
      discountAmt: discountAmt,
      totalPayable: totalPayable,
      paymentMethod: paymentMethod,
      notes: notes,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      shopImageBytes: imageBytes,
    );

    final pdfBytes = await Isolate.run(() => _buildA4PdfBytes(params));

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Voucher_$voucherNo',
    );
  }

  static Future<void> generateAndPrintReceipt({
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
    double paperWidthMm = 56.7,
    String? customerLocation,
  }) async {
    final imageBytes = await _fetchShopImage(shopImage);
    final monoImageBytes = await _toMonochromePng(imageBytes);

    final params = PdfBuildParams(
      customerName: customerName,
      customerPhone: customerPhone,
      staffName: staffName,
      voucherNo: voucherNo,
      orderId: orderId,
      dateTime: dateTime,
      items: items,
      discountPct: discountPct,
      subtotal: subtotal,
      discountAmt: discountAmt,
      totalPayable: totalPayable,
      paymentMethod: paymentMethod,
      notes: notes,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      shopImageBytes: monoImageBytes,
      paperWidthMm: paperWidthMm,
      customerLocation: customerLocation,
    );

    final pdfBytes = await Isolate.run(() => _buildReceiptPdfBytes(params));

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Receipt_$voucherNo',
      format: PdfPageFormat(
        paperWidthMm * PdfPageFormat.mm,
        297 * PdfPageFormat.mm,
      ),
    );
  }

  static Future<Uint8List> exportA4Pdf({
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
    final imageBytes = await _fetchShopImage(shopImage);

    final params = PdfBuildParams(
      customerName: customerName,
      customerPhone: customerPhone,
      staffName: staffName,
      voucherNo: voucherNo,
      orderId: orderId,
      dateTime: dateTime,
      items: items,
      discountPct: discountPct,
      subtotal: subtotal,
      discountAmt: discountAmt,
      totalPayable: totalPayable,
      paymentMethod: paymentMethod,
      notes: notes,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      shopImageBytes: imageBytes,
    );

    return await Isolate.run(() => _buildA4PdfBytes(params));
  }

  static Future<Uint8List> exportReceiptPdf({
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
    double paperWidthMm = 56.7,
    String? customerLocation,
  }) async {
    final imageBytes = await _fetchShopImage(shopImage);
    final monoImageBytes = await _toMonochromePng(imageBytes);

    final params = PdfBuildParams(
      customerName: customerName,
      customerPhone: customerPhone,
      staffName: staffName,
      voucherNo: voucherNo,
      orderId: orderId,
      dateTime: dateTime,
      items: items,
      discountPct: discountPct,
      subtotal: subtotal,
      discountAmt: discountAmt,
      totalPayable: totalPayable,
      paymentMethod: paymentMethod,
      notes: notes,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      shopImageBytes: monoImageBytes,
      paperWidthMm: paperWidthMm,
      customerLocation: customerLocation,
    );

    return await Isolate.run(() => _buildReceiptPdfBytes(params));
  }
}
