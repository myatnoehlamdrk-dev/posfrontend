import 'package:flutter/material.dart';
import 'package:posfrontend/features/cart/data/cart_store.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_card_entity.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_item_entity.dart';
import 'package:posfrontend/features/cart/presentation/screens/cart_card_screen.dart';
import 'package:posfrontend/features/cart/presentation/widgets/cart_item_row.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_repository_impl.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

class AddToCartScreen extends StatefulWidget {
  const AddToCartScreen({super.key});

  @override
  State<AddToCartScreen> createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  @override
  void initState() {
    super.initState();
    CartStore.instance.addListener(_onCartChanged);
    CartStore.instance.init();
    _syncFromBackend();
  }

  @override
  void dispose() {
    CartStore.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _syncFromBackend() async {
    try {
      final result = await SaleHistoryRepositoryImpl().getOrders(page: 1, perPage: 100);
      final data = result['data'];
      if (data is! List) return;
      final cards = <CartCardEntity>[];
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final status = item['status']?.toString() ?? '';
        if (status != 'draft') continue;
        final card = _cardFromOrder(item);
        if (card != null) cards.add(card);
      }
      await CartStore.instance.mergeCards(cards);
    } catch (_) {
      // Backend sync is best-effort; local cards still shown
    }
  }

  CartCardEntity? _cardFromOrder(Map<String, dynamic> json) {
    final orderId = json['id']?.toString() ?? '';
    if (orderId.isEmpty) return null;
    final rawItems = json['items'];
    if (rawItems is! List || rawItems.isEmpty) return null;
    final items = <CartItemEntity>[];
    for (final raw in rawItems) {
      if (raw is! Map<String, dynamic>) continue;
      final qty = (raw['quantity'] as num?)?.toInt() ?? 0;
      final price = (raw['unitPrice'] as num?)?.toDouble() ?? 0.0;
      if (qty <= 0) continue;
      items.add(CartItemEntity(
        productId: raw['productId']?.toString() ?? '',
        productName: raw['productName']?.toString() ?? '',
        unitPrice: price,
        quantity: qty,
        size: (raw['size'] as String?)?.trim().isNotEmpty == true
            ? (raw['size'] as String?)!.trim()
            : null,
        color: (raw['color'] as String?)?.trim().isNotEmpty == true
            ? (raw['color'] as String?)!.trim()
            : null,
      ));
    }
    if (items.isEmpty) return null;
    return CartCardEntity(
      id: 'backend-$orderId',
      orderId: orderId,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = CartStore.instance.value;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: AppTopBar(title: 'Add to Cart', showMenuButton: false, showBackButton: true),
            ),
            Expanded(
              child: cards.isEmpty
                  ? _emptyState()
                  : _cardsList(cards),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'Cart is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to your cart',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _cardsList(List<CartCardEntity> cards) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: cards.length,
      separatorBuilder: (ctx, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) => _CardTile(card: cards[index]),
    );
  }
}

class _CardTile extends StatelessWidget {
  final CartCardEntity card;

  const _CardTile({required this.card});

  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CartCardScreen(card: card)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_outlined, size: 18, color: purple),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${card.totalQuantity} item${card.totalQuantity == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(card.createdAt),
                          style: const TextStyle(fontSize: 11, color: gray),
                        ),
                      ],
                    ),
                  ),
                  PriceText(
                    card.total,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showDeleteDialog(context),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFE5E7EB)),
              for (final item in card.items.take(2)) ...[
                CartItemRow(item: item, dense: true),
                if (item != card.items.take(2).last)
                  const SizedBox(height: 8),
              ],
              if (card.items.length > 2) ...[
                const SizedBox(height: 8),
                Text(
                  '+${card.items.length - 2} more',
                  style: const TextStyle(fontSize: 11, color: purple, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Cart'),
          content: Text('Are you sure you want to delete this cart "${card.totalQuantity} items"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    if (card.orderId.isNotEmpty) {
      try {
        await OrderRepositoryImpl().deleteOrder(card.orderId);
      } catch (_) {
        // Backend order deletion failure is non-critical; card still removed
      }
    }
    if (!context.mounted) return;
    await CartStore.instance.removeCard(card.id);
  }
}