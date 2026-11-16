import 'dart:convert';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/shared/l10n/app_language.dart';
import 'package:posfrontend/shared/l10n/app_strings.dart';

/// Renders the sale receipt as ESC/POS bytes for a thermal printer.
///
/// The layout mirrors `_buildReceiptPdfBytes` in `voucher_pdf_service.dart`
/// field for field, in the same order and with the same English labels —
/// the PDF receipt and the paper coming out of the roll must read as the
/// same document. Two deliberate differences: the shop logo is skipped
/// (rasterising an image for cheap printers needs its own calibration, and
/// the text header carries the same information), and colour is expressed as
/// emphasis because ESC/POS has no purple.
class ThermalReceiptBuilder {
  /// Builds the job for the roll [paperSize] (`'58mm'` or `'80mm'`).
  static Future<List<int>> build(
    Map<String, dynamic> args, {
    required String paperSize,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperSize == '80mm' ? PaperSize.mm80 : PaperSize.mm58,
      profile,
      // latin1 (the package default) throws on non-Latin text — a product
      // name typed in Burmese would abort the whole job mid-receipt. UTF-8
      // is what modern ESC/POS firmware expects for anything beyond ASCII.
      codec: utf8,
    );

    // Print is English by design, exactly like the PDF receipt: one receipt
    // style for every shop, whatever language the UI runs in.
    final t = AppStrings.ofLanguage(AppLanguage.english);
    final dateTime = args['dateTime'] as DateTime;
    final items = (args['items'] as List).whereType<SaleItemEntity>().toList();
    // `+=` rebinds rather than appending (it is `bytes = bytes + part`), so
    // this buffer stays a local that grows by rebinding — which is also why
    // [_infoRow] returns its row instead of writing into a passed-in list.
    var bytes = <int>[];

    bytes += generator.reset();

    // --- Shop block -------------------------------------------------------
    final shopName = args['shopName'] as String?;
    if (shopName != null && shopName.isNotEmpty) {
      bytes += generator.text(
        shopName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
    }
    bytes += _infoRow(generator, t.t('Location'), args['shopAddress']);
    bytes += _infoRow(generator, t.t('Shop Contact'), args['shopPhone']);
    bytes += _infoRow(generator, t.t('Invoice no'), args['voucherNo']);
    bytes += generator.hr();

    // --- Who / when -------------------------------------------------------
    bytes += _infoRow(generator, t.t('Date'), dateTime.toShortDate());
    bytes += _infoRow(
      generator,
      t.t('Time'),
      dateTime.toFormattedDateTime().split(' ').skip(1).join(' '),
    );
    bytes += _infoRow(generator, t.t('Customer'), args['customerName']);
    bytes += _infoRow(generator, t.t('Phone'), args['customerPhone']);
    bytes += _infoRow(generator, t.t('Location'), args['customerLocation']);
    bytes += generator.hr();

    // --- Items ------------------------------------------------------------
    bytes += generator.row([
      PosColumn(
        text: t.t('Item'),
        width: 7,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: t.t('Qty'),
        width: 2,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
      PosColumn(
        text: t.t('Total'),
        width: 3,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    for (final item in items) {
      bytes += generator.row([
        PosColumn(text: item.productName, width: 7),
        PosColumn(
          text: '${item.quantity}',
          width: 2,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: item.subtotal.withCommas(),
          width: 3,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.hr();

    // --- Summary ----------------------------------------------------------
    final subtotal = args['subtotal'] as double;
    final discountPct = args['discountPct'] as double;
    final discountAmt = args['discountAmt'] as double;
    final totalPayable = args['totalPayable'] as double;

    bytes += _infoRow(generator, t.t('Subtotal'), subtotal.withCommas());
    if (discountPct > 0) {
      bytes += generator.row([
        PosColumn(
          text: t
              .t('Discount ({v1}%)')
              .replaceAll('{v1}', discountPct.asPercent()),
          width: 7,
        ),
        PosColumn(
          text: '-${discountAmt.withCommas()}',
          width: 5,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    }
    bytes += generator.hr(ch: '=');
    // Single-size, not double: a wide MMK total at double width would be
    // pushed left into the TOTAL label by the row's right-alignment maths.
    bytes += generator.row([
      PosColumn(
        text: t.t('TOTAL'),
        width: 7,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: totalPayable.withCommas(),
        width: 5,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    bytes += _infoRow(generator, t.t('Payment'), args['paymentMethod']);

    final notes = args['notes'] as String?;
    if (notes != null && notes.isNotEmpty) {
      bytes += generator.text(
        t.t('Notes: {v1}').replaceAll('{v1}', notes),
        styles: const PosStyles(bold: true),
      );
    }

    // --- Footer -----------------------------------------------------------
    bytes += generator.text(
      t.t('Thank you!'),
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      t.t('Items: {v1}').replaceAll('{v1}', '${items.length}'),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);
    // Printers without a cutter ignore the cut command; they just keep
    // feeding, which is why the trailing feed comes before it.
    bytes += generator.cut();

    return bytes;
  }

  /// A label left, value right — the receipt's workhorse row. [value] null or
  /// empty drops the row entirely, mirroring the PDF's conditional rows.
  ///
  /// [Generator] methods return their bytes rather than appending, and a
  /// `+=` inside a helper would only rebind the helper's own parameter, so
  /// the row comes back for the caller to add to its buffer.
  static List<int> _infoRow(Generator generator, String label, Object? value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return const [];
    return generator.row([
      PosColumn(text: label, width: 5, styles: const PosStyles(bold: true)),
      PosColumn(
        text: text,
        width: 7,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
  }
}
