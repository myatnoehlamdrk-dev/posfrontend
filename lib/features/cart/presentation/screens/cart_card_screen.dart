import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:flutter/services.dart';
import 'package:posfrontend/features/cart/data/cart_store.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_card_entity.dart';
import 'package:posfrontend/features/cart/presentation/widgets/cart_item_row.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/presentation/screens/new_sale_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/pressable_card.dart';
import 'package:posfrontend/shared/widgets/totals_panel.dart';

class CartCardScreen extends StatefulWidget {
  final CartCardEntity card;

  const CartCardScreen({super.key, required this.card});

  @override
  State<CartCardScreen> createState() => _CartCardScreenState();
}

class _CartCardScreenState extends State<CartCardScreen> {
  double get _total => widget.card.total;

  Future<void> _goCheckout() async {
    final items = widget.card.items
        .map(
          (e) => SaleItemEntity(
            productId: e.productId,
            productName: e.productName,
            imageUrl: e.imageUrl,
            unitPrice: e.unitPrice,
            quantity: e.quantity,
            size: e.size,
            color: e.color,
            category: e.category,
          ),
        )
        .toList();
    final orderId = widget.card.orderId.isNotEmpty ? widget.card.orderId : null;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NewSaleScreen(initialItems: items, existingOrderId: orderId),
      ),
    );
    if (!mounted) return;
    await CartStore.instance.removeCard(widget.card.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t('Checkout'),
              showMenuButton: false,
              showBackButton: true,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: widget.card.items.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.border),
                    ),
                    child: CartItemRow(item: widget.card.items[index]),
                  );
                },
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TotalsPanel(
              padding: EdgeInsets.zero,
              itemCount: widget.card.totalQuantity,
              subtotal: _total,
              discountAmount: 0,
              totalPayable: _total,
              showSubtotal: false,
              divider: TotalsDividerStyle.none,
            ),
            const SizedBox(height: 14),
            _checkoutButton(),
          ],
        ),
      ),
    );
  }

  /// Deliberately not a filled gradient.
  ///
  /// The total above is the number being confirmed, so the action that follows
  /// it is supporting cast. A solid saturated button would pull focus off the
  /// amount and read as the primary thing on the screen, which is what it used
  /// to do. Tinted fill, hairline border, light-violet label — the same violet
  /// the welcome screen paints its caption in, and lighter than the brand
  /// purple so it cannot pass for a second primary action: present, but no
  /// longer competing.
  ///
  /// The ink ripple this used to carry is gone, replaced by press physics: this
  /// is the one tap on the screen that spends money, so it answers the finger
  /// with a dip and a firmer tick rather than a soft bloom. The dip is shallow
  /// and the release is slow, which keeps a double-tap from reading as one
  /// confident press.
  Widget _checkoutButton() {
    final p = context.palette;

    return PressableCard(
      onTap: _goCheckout,
      haptic: HapticFeedback.mediumImpact,
      pressedScale: 0.98,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.selectionTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.lightViolet.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.lightViolet,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.l10n.t('Proceed to Checkout'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.lightViolet,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
