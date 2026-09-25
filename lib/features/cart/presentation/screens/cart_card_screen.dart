import 'package:flutter/material.dart';
import 'package:posfrontend/features/cart/data/cart_store.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_card_entity.dart';
import 'package:posfrontend/features/cart/presentation/widgets/cart_item_row.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/presentation/screens/new_sale_screen.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

class CartCardScreen extends StatefulWidget {
  final CartCardEntity card;

  const CartCardScreen({super.key, required this.card});

  @override
  State<CartCardScreen> createState() => _CartCardScreenState();
}

class _CartCardScreenState extends State<CartCardScreen> {
  static const Color titleColor = Color(0xFF111827);

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenTopBar(
              title: 'Checkout',
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.card.totalQuantity} Items',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  PriceText(
                    _total,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _goCheckout,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Checkout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
