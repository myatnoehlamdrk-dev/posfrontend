import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/l10n/app_strings.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/cached_product_image.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/shared/widgets/totals_panel.dart';

String _fmtPrice(double value) => value.withCommas();

TextStyle _monoStyle({
  double fontSize = 13,
  FontWeight fontWeight = FontWeight.normal,
  Color? color,
}) {
  return GoogleFonts.robotoMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

class SalePreviewScreen extends StatelessWidget {
  final String customerName;
  final String? customerPhone;
  final String? customerLocation;
  final String staffName;
  final String voucherNo;
  final String orderId;
  final DateTime dateTime;
  final List<SaleItemEntity> items;
  final double discountPct;
  final double subtotal;
  final double discountAmt;
  final double totalPayable;
  final String paymentMethod;
  final String? notes;
  final String? shopName;
  final String? shopAddress;
  final String? shopPhone;
  final String? shopEmail;
  final String? shopImage;

  const SalePreviewScreen({
    super.key,
    required this.customerName,
    this.customerPhone,
    this.customerLocation,
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
    this.shopEmail,
    this.shopImage,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffoldBg,
      appBar: AppBar(
        backgroundColor: p.surface,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          context.l10n.t('Invoice Preview'),
          style: TextStyle(
            fontSize: AppTypography.bodyLargeSize,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: kPurple),
            tooltip: 'Print',
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _header(),
                  _divider(p),
                  _invoiceInfo(p),
                  _divider(p),
                  _customerSection(p),
                  _divider(p),
                  _itemsHeader(p),
                  _itemsList(p),
                  _divider(p),
                  _summarySection(p),
                  if (notes?.isNotEmpty == true) _notesSection(p),
                  _footer(p),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandPurpleDark, AppColors.brandPurpleDarker],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shopImage?.isNotEmpty == true)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: shopImage!.startsWith('http')
                  ? CachedProductImage(
                      url: resolveMediaUrl(shopImage)!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      memCacheWidth: 256,
                      errorWidget: _shopPlaceholder(),
                    )
                  : _base64Image(shopImage!),
            )
          else
            _shopPlaceholder(),
          const SizedBox(height: 10),
          if (shopName?.isNotEmpty == true)
            Text(
              shopName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppTypography.titleSmallSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (shopName?.isNotEmpty == true) const SizedBox(height: 4),
          if (shopAddress?.isNotEmpty == true)
            Text(
              shopAddress!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: AppTypography.labelSmallSize,
              ),
            ),
          if (shopPhone?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                shopPhone!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppTypography.labelSmallSize,
                ),
              ),
            ),
          if (shopEmail?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                shopEmail!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppTypography.labelSmallSize,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            AppStrings.current.t('INVOICE'),
            style: TextStyle(
              color: Colors.white,
              fontSize: AppTypography.titleMediumSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            voucherNo,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: AppTypography.labelMediumSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppPalette p) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: p.border),
    );
  }

  Widget _invoiceInfo(AppPalette p) {
    final dateStr = dateTime.toShortDate();
    final timeStr = dateTime.toFormattedDateTime().split(' ').skip(1).join(' ');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _infoRow(p, 'Voucher ID', voucherNo),
          const SizedBox(height: 8),
          _infoRow(p, 'Order ID', orderId),
          const SizedBox(height: 8),
          _infoRow(p, 'Date', dateStr),
          const SizedBox(height: 8),
          _infoRow(p, 'Time', timeStr),
          const SizedBox(height: 8),
          _infoRow(p, 'Staff', staffName),
        ],
      ),
    );
  }

  Widget _infoRow(AppPalette p, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _monoStyle(
              fontSize: AppTypography.labelMediumSize,
              color: p.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _monoStyle(
              fontSize: AppTypography.labelMediumSize,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _customerSection(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.selectionTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: kPurple, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.current.t('Customer'),
                      style: TextStyle(
                        fontSize: AppTypography.labelSmallSize,
                        color: p.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: _monoStyle(
                        fontSize: AppTypography.bodySmallSize,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    if (customerPhone?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        customerPhone!,
                        style: _monoStyle(
                          fontSize: AppTypography.labelSmallSize,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                    if (customerLocation?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        customerLocation!,
                        style: _monoStyle(
                          fontSize: AppTypography.labelSmallSize,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemsHeader(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              AppStrings.current.t('Item'),
              style: _monoStyle(
                fontSize: AppTypography.labelSmallSize,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              AppStrings.current.t('Qty'),
              textAlign: TextAlign.center,
              style: _monoStyle(
                fontSize: AppTypography.labelSmallSize,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppStrings.current.t('Price'),
              textAlign: TextAlign.right,
              style: _monoStyle(
                fontSize: AppTypography.labelSmallSize,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppStrings.current.t('Total'),
              textAlign: TextAlign.right,
              style: _monoStyle(
                fontSize: AppTypography.labelSmallSize,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsList(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final variant = [
            if (item.size != null && item.size != 'Regular') item.size,
            if (item.color?.isNotEmpty == true) item.color,
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: i < items.length - 1
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: p.border, width: 0.5),
                    ),
                  )
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _monoStyle(
                          fontSize: AppTypography.labelMediumSize,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      if (variant.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          variant,
                          style: _monoStyle(
                            fontSize: AppTypography.labelSmallSize,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    AppStrings.current
                        .t('{v1}')
                        .replaceAll('{v1}', (item.quantity).toString()),
                    textAlign: TextAlign.center,
                    style: _monoStyle(
                      fontSize: AppTypography.labelMediumSize,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _fmtPrice(item.unitPrice),
                      textAlign: TextAlign.right,
                      style: _monoStyle(
                        fontSize: AppTypography.labelSmallSize,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _fmtPrice(item.subtotal),
                      textAlign: TextAlign.right,
                      style: _monoStyle(
                        fontSize: AppTypography.labelSmallSize,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _summarySection(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TotalsPanel(
        padding: EdgeInsets.zero,
        mono: true,
        divider: TotalsDividerStyle.dashed,
        format: (value) => value.withCommas(),
        subtotal: subtotal,
        discountPercent: discountPct,
        discountAmount: discountAmt,
        totalPayable: totalPayable,
        footer: _paymentMethodChip(p),
      ),
    );
  }

  Widget _paymentMethodChip(AppPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.selectionTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              AppStrings.current.t('Payment Method'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTypography.labelMediumSize,
                color: p.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              paymentMethod,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _monoStyle(
                fontSize: AppTypography.labelMediumSize,
                fontWeight: FontWeight.w600,
                color: kPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesSection(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.warningBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.current.t('Notes'),
              style: TextStyle(
                fontSize: AppTypography.labelSmallSize,
                fontWeight: FontWeight.w600,
                color: p.warningFg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notes!,
              style: TextStyle(
                fontSize: AppTypography.labelSmallSize,
                color: p.warningFg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(AppPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 32, color: p.successFg),

          const SizedBox(height: 8),
          Text(
            AppStrings.current.t('Thank you for your purchase!'),
            style: TextStyle(
              fontSize: AppTypography.labelMediumSize,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.current
                .t('Total Items: {v1}')
                .replaceAll('{v1}', (items.length).toString()),
            style: TextStyle(
              fontSize: AppTypography.labelSmallSize,
              color: p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.store, color: Colors.white, size: 32),
    );
  }

  Widget _base64Image(String data) {
    try {
      Uint8List bytes = base64Decode(data);
      return Image.memory(
        bytes,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        cacheWidth: 256,
      );
    } catch (_) {
      return _shopPlaceholder();
    }
  }
}
