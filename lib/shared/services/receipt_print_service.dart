import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/shared/services/voucher_pdf_service.dart';

/// The receipt-output preference a sale reads when it finishes.
///
/// One setting drives both sale surfaces: the choice made in the new-sale
/// screen's print-settings sheet decides what quick sale does too, under the
/// same [SharedPreferences] keys.
class SalePrintSettings {
  const SalePrintSettings({
    required this.output,
    required this.paperSize,
    this.btPrinterAddress = '',
    this.btPrinterName = '',
  });

  /// Share the voucher as an A4 PDF after each sale — the only output that
  /// works everywhere, including the browser, so it is also the default.
  static const String outputPdf = 'pdf';

  /// Send ESC/POS bytes to a paired Bluetooth thermal printer directly.
  static const String outputBluetooth = 'bluetooth';

  /// Send ESC/POS bytes to a network thermal printer over raw TCP.
  static const String outputWifi = 'wifi';

  /// Send ESC/POS bytes to a USB thermal printer over WebUSB (browser only).
  static const String outputUsb = 'usb';

  /// `'pdf'`, `'bluetooth'`, `'wifi'` or `'usb'`.
  final String output;

  /// `'80mm'` or `'58mm'` — the roll the thermal outputs lay the receipt out
  /// for. Ignored by the [outputPdf] path, which prints full-width.
  final String paperSize;

  /// Address of the chosen Bluetooth printer (a MAC on Android, a Core
  /// Bluetooth UUID string on iOS). Only read when [output] is
  /// [outputBluetooth].
  final String btPrinterAddress;

  /// Display name of that printer, so the settings sheet can show which one
  /// is selected without re-querying the adapter.
  final String btPrinterName;

  static const _keyOutput = 'print_output';
  static const _keyPaperSize = 'print_paper_size';
  static const _keyBtAddress = 'print_bt_address';
  static const _keyBtName = 'print_bt_name';

  // Read-only on the migration path: keys older builds wrote.
  static const _legacyKeyPrintVoucher = 'print_voucher_enabled';
  static const _legacyKeyFormat = 'print_format';

  static Future<SalePrintSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SalePrintSettings(
      output: prefs.getString(_keyOutput) ?? _migrateOutput(prefs),
      paperSize: prefs.getString(_keyPaperSize) ?? '58mm',
      btPrinterAddress: prefs.getString(_keyBtAddress) ?? '',
      btPrinterName: prefs.getString(_keyBtName) ?? '',
    );
  }

  /// Maps the pre-output choices onto the single setting. A till that
  /// auto-printed a *thermal* voucher asked for paper with no dialog, so it
  /// keeps getting paper from the only direct thermal path that existed as a
  /// configured destination — the network printer. A4 vouchers, PDF-only
  /// tills and fresh installs stay on the PDF default.
  static String _migrateOutput(SharedPreferences prefs) {
    final voucherOn = prefs.getBool(_legacyKeyPrintVoucher) ?? false;
    final thermal =
        (prefs.getString(_legacyKeyFormat) ?? 'thermal') == 'thermal';
    return voucherOn && thermal ? outputWifi : outputPdf;
  }

  static Future<void> setOutput(String output) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOutput, output);
  }

  static Future<void> setBluetoothPrinter({
    required String address,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBtAddress, address);
    await prefs.setString(_keyBtName, name);
  }

  /// Writes [paperSize] straight into the key the sheet reads, without
  /// touching the other settings.
  ///
  /// The printer profile store calls this when the default printer changes:
  /// the printer's physical roll is the fact, and the receipt layout is what
  /// has to follow it, so the sheet picks the new size up on its next open.
  static Future<void> setPaperSize(String paperSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPaperSize, paperSize);
  }

  /// Paper width the receipt is laid out for. The PDF is drawn a couple of
  /// millimetres inside the physical roll so nothing is clipped by the
  /// printer's unprintable margins.
  double get paperWidthMm => paperSize == '80mm' ? 78.0 : 56.7;

  /// Whether the selected output sends bytes straight to a thermal printer.
  bool get isThermal => output != outputPdf;
}

/// Executes the two things that can happen to a finished sale's voucher:
/// share it as an A4 PDF, or hand it to the OS print dialog.
///
/// The direct thermal prints live in `sale_output_service.dart`; [printReceipt]
/// is now only the fallback — a failure snackbar offering "Open print dialog"
/// so a bad connection still ends with paper rather than an apology.
class ReceiptPrintService {
  /// The map every voucher renderer reads. The caller resolves the shop (it
  /// owns the scope widget) and passes its fields in.
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

  /// Opens the OS print dialog on a receipt laid out for the roll
  /// ([SalePrintSettings.paperWidthMm]) — the manual way out when a direct
  /// thermal print fails.
  static Future<void> printReceipt(
    Map<String, dynamic> args,
    SalePrintSettings settings,
  ) async {
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
