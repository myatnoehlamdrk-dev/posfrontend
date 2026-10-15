import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/shared/services/voucher_pdf_service.dart';

/// The receipt-printing preferences a sale reads when it finishes.
///
/// These live under the same [SharedPreferences] keys the new-sale screen's
/// print-settings sheet writes, so one setting drives both sale surfaces: a
/// till that auto-prints 80mm vouchers from the new-sale screen auto-prints
/// the same from quick sale.
class SalePrintSettings {
  const SalePrintSettings({
    required this.exportPdf,
    required this.printVoucher,
    required this.format,
    required this.paperSize,
  });

  /// Share an A4 PDF after each sale (the new-sale screen's default).
  final bool exportPdf;

  /// Send the receipt to the printer with no dialog (what a till wants).
  final bool printVoucher;

  /// `'thermal'` for an 80/58mm roll, anything else for an A4-style voucher.
  final String format;

  /// `'80mm'` or `'58mm'`; only read when [format] is `'thermal'`.
  final String paperSize;

  // Must match the constants in the new-sale screen's settings sheet — the
  // sheet writes them, both screens read them.
  static const _keyExportPdf = 'print_pdf_export';
  static const _keyPrintVoucher = 'print_voucher_enabled';
  static const _keyFormat = 'print_format';
  static const _keyPaperSize = 'print_paper_size';

  static Future<SalePrintSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SalePrintSettings(
      exportPdf: prefs.getBool(_keyExportPdf) ?? true,
      printVoucher: prefs.getBool(_keyPrintVoucher) ?? false,
      format: prefs.getString(_keyFormat) ?? 'thermal',
      paperSize: prefs.getString(_keyPaperSize) ?? '58mm',
    );
  }

  /// Paper width the receipt is laid out for. The PDF is drawn a couple of
  /// millimetres inside the physical roll so nothing is clipped by the
  /// printer's unprintable margins.
  double get paperWidthMm => paperSize == '80mm' ? 78.0 : 56.7;
}

/// Executes the two things that can happen to a finished sale's voucher:
/// share it as an A4 PDF, or print it (thermally or as A4).
///
/// Extracted from the new-sale screen so quick sale can offer the identical
/// behaviour without a second copy of the arg-shuffling drifting apart.
class ReceiptPrintService {
  /// The map both [exportPdf] and [printReceipt] read. The caller resolves
  /// the shop (it owns the scope widget) and passes its fields in.
  static Map<String, dynamic> buildArgs({
    required String customerName,
    String? customerPhone,
    String? customerLocation,
    required String staffName,
    required String voucherNo,
    required String orderId,
    required List<SaleItemEntity> items,
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
  }) {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerLocation': customerLocation,
      'staffName': staffName,
      'voucherNo': voucherNo,
      'orderId': orderId,
      'dateTime': DateTime.now(),
      'items': items,
      'discountPct': discountPct,
      'subtotal': subtotal,
      'discountAmt': discountAmt,
      'totalPayable': totalPayable,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'shopName': shopName,
      'shopAddress': shopAddress,
      'shopPhone': shopPhone,
      'shopImage': shopImage,
    };
  }

  /// Sends the receipt to the printer. Thermal mode lays the voucher out on
  /// the roll ([SalePrintSettings.paperWidthMm]); the other mode prints the
  /// full-width voucher through the OS print dialog.
  static Future<void> printReceipt(
    Map<String, dynamic> args,
    SalePrintSettings settings,
  ) async {
    if (settings.format == 'thermal') {
      await VoucherPdfService.generateAndPrintReceipt(
        customerName: args['customerName'],
        customerPhone: args['customerPhone'],
        staffName: args['staffName'],
        voucherNo: args['voucherNo'],
        orderId: args['orderId'],
        dateTime: args['dateTime'],
        items: args['items'],
        discountPct: args['discountPct'],
        subtotal: args['subtotal'],
        discountAmt: args['discountAmt'],
        totalPayable: args['totalPayable'],
        paymentMethod: args['paymentMethod'],
        notes: args['notes'],
        shopName: args['shopName'],
        shopAddress: args['shopAddress'],
        shopPhone: args['shopPhone'],
        shopImage: args['shopImage'],
        paperWidthMm: settings.paperWidthMm,
        customerLocation: args['customerLocation'],
      );
    } else {
      await VoucherPdfService.generateAndPrint(
        customerName: args['customerName'],
        customerPhone: args['customerPhone'],
        staffName: args['staffName'],
        voucherNo: args['voucherNo'],
        orderId: args['orderId'],
        dateTime: args['dateTime'],
        items: args['items'],
        discountPct: args['discountPct'],
        subtotal: args['subtotal'],
        discountAmt: args['discountAmt'],
        totalPayable: args['totalPayable'],
        paymentMethod: args['paymentMethod'],
        notes: args['notes'],
        shopName: args['shopName'],
        shopAddress: args['shopAddress'],
        shopPhone: args['shopPhone'],
        shopImage: args['shopImage'],
      );
    }
  }

  /// Builds the A4 voucher and hands it to the OS share sheet.
  static Future<void> exportPdf(Map<String, dynamic> args) async {
    final pdfBytes = await VoucherPdfService.exportA4Pdf(
      customerName: args['customerName'],
      customerPhone: args['customerPhone'],
      staffName: args['staffName'],
      voucherNo: args['voucherNo'],
      orderId: args['orderId'],
      dateTime: args['dateTime'],
      items: args['items'],
      discountPct: args['discountPct'],
      subtotal: args['subtotal'],
      discountAmt: args['discountAmt'],
      totalPayable: args['totalPayable'],
      paymentMethod: args['paymentMethod'],
      notes: args['notes'],
      shopName: args['shopName'],
      shopAddress: args['shopAddress'],
      shopPhone: args['shopPhone'],
      shopImage: args['shopImage'],
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Voucher_${args['voucherNo']}.pdf',
    );
  }
}
