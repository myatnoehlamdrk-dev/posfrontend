import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/sale_view_model.dart';
import 'package:posfrontend/features/sale/presentation/widgets/percent_input_formatter.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/cached_product_image.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/quantity_control.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

/// The cart the quick-sale screen reveals beside the product grid.
///
/// It is deliberately a different shape from the new-sale screen's checkout
/// column: there the cashier is building a considered order, here they are at
/// the till with a queue behind them. So the editable detail (discount,
/// payment method, customer) scrolls with the items, and the two things needed
/// to finish — the running total and `Complete Sale` — are pinned in their own
/// bar at the bottom where they never scroll out of reach.
///
/// The panel owns no state. Everything lives in the [SaleViewModel] it is
/// handed, the same object the new-sale screen uses, so this is a view over a
/// sale rather than a second sale to keep in sync.
class QuickSaleCartPanel extends StatefulWidget {
  const QuickSaleCartPanel({
    super.key,
    required this.sale,
    required this.onClose,
    this.onSaleCompleted,
  });

  final SaleViewModel sale;

  /// Closes the surface this panel is drawn in — the side container on a wide
  /// window, the sheet on a phone.
  final VoidCallback onClose;

  /// Called after a sale is stored, so the screen can refresh stock.
  final VoidCallback? onSaleCompleted;

  @override
  State<QuickSaleCartPanel> createState() => _QuickSaleCartPanelState();
}

class _QuickSaleCartPanelState extends State<QuickSaleCartPanel> {
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _customerCtrl = TextEditingController();

  AppPalette get _p => context.palette;
  Color get _titleColor => _p.textPrimary;
  Color get _mutedColor => _p.textSecondary;
  Color get _borderColor => _p.border;

  @override
  void dispose() {
    _discountCtrl.dispose();
    _customerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.sale.isSubmitting || !widget.sale.hasItems) return;
    final name = _customerCtrl.text.trim();
    widget.sale.setCustomerName(name.isEmpty ? 'Customer' : name);

    final success = await widget.sale.submitSale(
      staffName: AuthScope.userOf(context)?.fullName ?? 'Staff',
    );

    if (!success) {
      if (!mounted) return;
      showErrorMessage(
        context,
        widget.sale.errorMessage ?? 'Failed to save sale',
      );
      return;
    }
    if (!mounted) return;

    _customerCtrl.clear();
    _discountCtrl.text = '0';
    widget.sale.clearCart();
    widget.onSaleCompleted?.call();
    showSuccessMessage(context, context.l10n.t('Sale saved successfully!'));
  }

  void _confirmClear() {
    if (!widget.sale.hasItems) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          context.l10n.t('Clear'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          context.l10n.t('Remove all items from this sale?'),
          style: TextStyle(fontSize: 14, color: _mutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.l10n.t('Cancel'),
              style: TextStyle(color: _mutedColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _discountCtrl.text = '0';
              _customerCtrl.clear();
              widget.sale.clearCart();
            },
            child: Text(
              context.l10n.t('Clear'),
              style: TextStyle(color: _p.dangerFg),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The panel is a view over the sale: every quantity change, discount edit
    // and submission state change has to repaint it without a setState.
    return ListenableBuilder(
      listenable: widget.sale,
      builder: (context, _) {
        return Column(
          children: [
            _header(),
            Divider(height: 1, color: _borderColor),
            Expanded(child: _body()),
            Divider(height: 1, color: _borderColor),
            _checkoutBar(),
          ],
        );
      },
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _p.selectionTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              color: _p.accentText,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.t('Current Sale'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n
                      .t('{v1} items')
                      .replaceAll('{v1}', widget.sale.totalItems.toString()),
                  style: TextStyle(fontSize: 12, color: _mutedColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            tooltip: context.l10n.t('Close'),
            icon: Icon(Icons.close, size: 20, color: _mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final items = widget.sale.items;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if (items.isEmpty) _emptyHint() else ...[
          for (var i = 0; i < items.length; i++)
            _itemRow(index: i, item: items[i]),
          const SizedBox(height: 4),
        ],
        _detailCard(),
        const SizedBox(height: 12),
        _clearButton(),
      ],
    );
  }

  Widget _emptyHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.touch_app_outlined, size: 40, color: _p.textMuted),
          const SizedBox(height: 12),
          Text(
            context.l10n.t('Tap a product to add it to this sale'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _itemRow({required int index, required SaleItemEntity item}) {
    final variantLine = [
      if (item.size != null && item.size != 'Regular') item.size,
      if (item.color?.isNotEmpty == true) item.color,
    ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _p.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  color: _p.chipBg,
                  child: item.imageUrl != null
                      ? CachedProductImage(
                          url: item.imageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          memCacheWidth: 160,
                        )
                      : Icon(
                          CatalogProductView.iconFor(item.category),
                          color: _mutedColor,
                          size: 18,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    if (variantLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        variantLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: _mutedColor),
                      ),
                    ],
                    const SizedBox(height: 2),
                    PriceText(
                      item.unitPrice,
                      style: TextStyle(fontSize: 11, color: _mutedColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => widget.sale.removeItem(index),
                tooltip: context.l10n.t('Remove'),
                icon: Icon(
                  Icons.delete_outline,
                  size: 17,
                  color: _p.dangerFg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              QuantityControl(
                quantity: item.quantity,
                onChanged: (next) =>
                    widget.sale.updateItemQuantity(index, next - item.quantity),
              ),
              const Spacer(),
              PriceText(
                item.subtotal,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Discount, payment method and customer — everything that can be edited but
  /// is not needed on every single sale, so it scrolls with the items.
  Widget _detailCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _p.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _discountRow(),
          const SizedBox(height: 12),
          _paymentDropdown(),
          const SizedBox(height: 12),
          _customerField(),
        ],
      ),
    );
  }

  Widget _discountRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.t('Subtotal'),
                style: TextStyle(fontSize: 12, color: _mutedColor),
              ),
              const SizedBox(height: 2),
              PriceText(
                widget.sale.subtotal,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _titleColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.t('Discount'),
                style: TextStyle(fontSize: 12, color: _mutedColor),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  PriceText(
                    widget.sale.discountAmount,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _discountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        const PercentInputFormatter(),
                      ],
                      onChanged: (v) =>
                          widget.sale.setDiscountPercent(double.tryParse(v) ?? 0),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        suffixText: '%',
                        suffixStyle: TextStyle(
                          fontSize: 11,
                          color: _mutedColor,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _p.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentDropdown() {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.t('Payment Method'),
            style: TextStyle(fontSize: 13, color: _mutedColor),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.sale.paymentMethod,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: [
                for (final label in const [
                  'Cash',
                  'Card',
                  'Mobile Pay',
                  'Other',
                ])
                  DropdownMenuItem(
                    value: label,
                    child: Text(
                      context.l10n.t(label),
                      style: TextStyle(fontSize: 13, color: _titleColor),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) widget.sale.setPaymentMethod(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _customerField() {
    return TextField(
      controller: _customerCtrl,
      style: TextStyle(fontSize: 13, color: _titleColor),
      decoration: InputDecoration(
        isDense: true,
        labelText: context.l10n.t('Customer (optional)'),
        labelStyle: TextStyle(fontSize: 12, color: _mutedColor),
        hintText: context.l10n.t('Customer'),
        hintStyle: TextStyle(fontSize: 12, color: _p.textMuted),
        prefixIcon: Icon(Icons.person_outline, size: 18, color: _mutedColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _p.primary),
        ),
      ),
    );
  }

  Widget _clearButton() {
    final enabled = widget.sale.hasItems;
    return OutlinedButton.icon(
      onPressed: enabled ? _confirmClear : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: _p.dangerFg,
        side: BorderSide(color: enabled ? _p.borderStrong : _borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: const Icon(Icons.delete_sweep_outlined, size: 17),
      label: Text(
        context.l10n.t('Clear'),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Pinned: the amount and the button that commits it do not scroll away.
  Widget _checkoutBar() {
    final submitting = widget.sale.isSubmitting;
    final canSubmit = widget.sale.hasItems && !submitting;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.t('Total'),
                    style: TextStyle(fontSize: 12, color: _mutedColor),
                  ),
                  const SizedBox(height: 2),
                  PriceText(
                    widget.sale.totalPayable,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _p.accentText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PressableSaleButton(
              enabled: canSubmit,
              submitting: submitting,
              label: context.l10n.t('Complete Sale'),
              icon: Icons.check_circle_outline,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// The commit button, shared by the panel and the cart bar so the two cannot
/// drift apart on what "saving" looks like.
class PressableSaleButton extends StatelessWidget {
  final bool enabled;
  final bool submitting;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const PressableSaleButton({
    super.key,
    required this.enabled,
    required this.submitting,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.brandPurple, AppColors.brandPurpleDark],
                )
              : null,
          color: enabled ? null : context.palette.borderStrong,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (submitting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              submitting ? context.l10n.t('Saving...') : label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
