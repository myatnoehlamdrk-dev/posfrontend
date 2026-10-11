import 'dart:math';

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:flutter/services.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/features/cart/data/cart_store.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_card_entity.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_item_entity.dart';
import 'package:posfrontend/features/cart/presentation/screens/cart_card_screen.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_repository_impl.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_message.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/pressable_card.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

/// A variant option a product offers, used by the shared variant picker.
class VariantOption {
  final String size;
  final String color;
  final int quantity;
  final double price;

  const VariantOption({
    this.size = '',
    this.color = '',
    this.quantity = 0,
    this.price = 0,
  });
}

/// A single variant with the quantity the shopper picked.
class VariantPick {
  final String size;
  final String color;
  final int qty;
  final double price;

  const VariantPick({
    this.size = '',
    this.color = '',
    this.qty = 0,
    this.price = 0,
  });

  String get title {
    final parts = <String>[
      if (size.isNotEmpty) size,
      if (color.isNotEmpty) color,
    ];
    return parts.isEmpty ? 'Default' : parts.join(' · ');
  }
}

/// Lets the shopper pick how many of each variant to take. The tally is capped
/// by per-variant stock, so this belongs to buying flows — not restocking.
Future<List<VariantPick>?> showVariantPicker(
  BuildContext context, {
  required String productName,
  required int productStock,
  required List<VariantOption> variants,
}) {
  return showDialog<List<VariantPick>>(
    context: context,
    builder: (_) => VariantPickDialog(
      productName: productName,
      productStock: productStock,
      variants: variants,
      onConfirm: (picks) => Navigator.of(context).pop(picks),
    ),
  );
}

class VariantPickDialog extends StatefulWidget {
  final String productName;
  final int productStock;
  final List<VariantOption> variants;
  final ValueChanged<List<VariantPick>> onConfirm;

  const VariantPickDialog({
    super.key,
    required this.productName,
    required this.productStock,
    required this.variants,
    required this.onConfirm,
  });

  @override
  State<VariantPickDialog> createState() => _VariantPickDialogState();
}

class _VariantPickDialogState extends State<VariantPickDialog> {
  AppPalette get _p => context.palette;
  Color get _mutedColor => _p.textSecondary;
  Color get _accentColor => _p.primary;
  Color get _titleColor => _p.textPrimary;
  Color get _borderColor => _p.border;

  final List<TextEditingController> _ctrls = [];
  late final List<int> _qtys;

  int get _totalPicked => _qtys.fold(0, (sum, q) => sum + q);

  int get _totalStock => widget.variants.fold(0, (sum, v) => sum + v.quantity);
  int get _productStock =>
      widget.productStock > 0 ? widget.productStock : _totalStock;

  @override
  void initState() {
    super.initState();
    _qtys = List.filled(widget.variants.length, 0);
    for (final _ in widget.variants) {
      _ctrls.add(TextEditingController(text: '0'));
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  int _maxFor(int i) {
    final other = _totalPicked - _qtys[i];
    return min(widget.variants[i].quantity, _productStock - other);
  }

  void _setQty(int i, int qty) {
    if (qty < 0) qty = 0;
    final maxQ = _maxFor(i);
    if (qty > maxQ) qty = maxQ;
    setState(() {
      _qtys[i] = qty;
      _ctrls[i].value = TextEditingValue(
        text: '$qty',
        selection: TextSelection.collapsed(offset: '$qty'.length),
      );
    });
  }

  void _fromCtrl(int i, String txt) {
    _setQty(i, int.tryParse(txt) ?? 0);
  }

  void _fillAll() {
    setState(() {
      var remaining = _productStock;
      for (var i = 0; i < _qtys.length; i++) {
        final take = min(widget.variants[i].quantity, remaining);
        _qtys[i] = take;
        remaining -= take;
        _ctrls[i].text = '$take';
      }
    });
  }

  void _confirm() {
    final picks = <VariantPick>[];
    for (var i = 0; i < _qtys.length; i++) {
      if (_qtys[i] > 0) {
        final v = widget.variants[i];
        picks.add(
          VariantPick(
            size: v.size,
            color: v.color,
            qty: _qtys[i],
            price: v.price,
          ),
        );
      }
    }
    widget.onConfirm(picks);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _p.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.t('Choose Variants'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            widget.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: _mutedColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n
                      .t('{v1} / {v2} pieces')
                      .replaceAll('{v1}', (_totalPicked).toString())
                      .replaceAll('{v2}', (_productStock).toString()),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _fillAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _p.selectionTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 13, color: _accentColor),
                      SizedBox(width: 4),
                      Text(
                        context.l10n.t('Fill all stock'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.variants.length; i++) _variantRow(i),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: _mutedColor),
          child: Text(context.l10n.t('Cancel')),
        ),
        FilledButton(
          onPressed: _totalPicked > 0 ? _confirm : null,
          style: FilledButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: Colors.white,
          ),
          child: Text(context.l10n.t('Add')),
        ),
      ],
    );
  }

  Widget _variantRow(int i) {
    final v = widget.variants[i];
    final qty = _qtys[i];
    final maxQ = _maxFor(i);
    final pick = VariantPick(
      size: v.size,
      color: v.color,
      qty: qty,
      price: v.price,
    );
    final title = pick.title;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: qty > 0 ? _accentColor : _borderColor,
          width: qty > 0 ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                size: 16,
                color: qty > 0 ? _accentColor : _mutedColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n
                          .t('Stock: {v1}')
                          .replaceAll('{v1}', (v.quantity).toString()),
                      style: TextStyle(fontSize: 11, color: _mutedColor),
                    ),
                  ],
                ),
              ),
              PriceText(
                v.price,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                qty > 0 ? 'Selected: $qty' : 'Tap + to select',
                style: TextStyle(
                  fontSize: 11,
                  color: qty > 0 ? _accentColor : _mutedColor,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _p.borderStrong),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _stepBtn(
                      Icons.remove,
                      qty > 0 ? () => _setQty(i, qty - 1) : null,
                    ),
                    SizedBox(
                      width: 38,
                      child: TextField(
                        controller: _ctrls[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 4,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _titleColor,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (t) => _fromCtrl(i, t),
                      ),
                    ),
                    _stepBtn(
                      Icons.add,
                      qty < maxQ ? () => _setQty(i, qty + 1) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return PressableCard(
      onTap: onTap,
      haptic: HapticFeedback.selectionClick,
      pressedScale: 0.88,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Icon(
          icon,
          size: 14,
          color: onTap == null ? _p.borderStrong : _mutedColor,
        ),
      ),
    );
  }
}

/// Where the shopper wants their items to go.
enum AddToCartChoice { newCard, existingCard }

/// Runs the shared add-to-cart flow: asks whether the items go on a new card
/// or an existing one, then lands the shopper on the cart card where the sale
/// is completed.
Future<void> addItemsToCart(
  BuildContext context,
  List<CartItemEntity> items,
  String productName,
) async {
  final choice = await showDialog<AddToCartChoice>(
    context: context,
    builder: (_) => AddToCartChoiceDialog(productName: productName),
  );
  if (choice == null || !context.mounted) return;
  if (choice == AddToCartChoice.newCard) {
    await _createNewCard(context, items);
    return;
  }
  await _appendToExistingCard(context, items);
}

Future<void> _createNewCard(
  BuildContext context,
  List<CartItemEntity> items,
) async {
  String createOrderId = '';
  try {
    createOrderId = await OrderRepositoryImpl().createOrder(
      userName: AuthScope.userOf(context)?.fullName ?? 'Staff',
      voucherNo: 'INV-${_random5()}',
      orderId: 'ORD-${_random5()}',
      items: items.map(_saleEntity).toList(),
      grandTotal: items.fold(0.0, (sum, e) => sum + e.subtotal),
      status: 'draft',
    );
  } on AppException catch (e) {
    if (!context.mounted) return;
    showErrorMessage(context, e.message);
    return;
  } catch (e) {
    if (!context.mounted) return;
    showErrorMessage(
      context,
      context.l10n
          .t('Failed to add to cart: {v1}')
          .replaceAll('{v1}', (e).toString()),
    );
    return;
  }

  final card = await CartStore.instance.addCard(items, orderId: createOrderId);
  if (!context.mounted || card == null) return;
  // A local id means the draft exists only on this device: no stock is
  // reserved server-side yet. Say so — a cashier who thinks the draft is
  // on the server will wait for a sync that is not coming.
  if (createOrderId.startsWith('local:')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.t('Saved on this device')),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CartCardScreen(card: card)));
}

Future<void> _appendToExistingCard(
  BuildContext context,
  List<CartItemEntity> items,
) async {
  final cards = CartStore.instance.value
      .where((c) => c.orderId.isNotEmpty)
      .toList();
  if (cards.isEmpty) {
    if (!context.mounted) return;
    showErrorMessage(
      context,
      'No existing card to add into. Start a new card first.',
    );
    return;
  }
  final card = await showModalBottomSheet<CartCardEntity>(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => ExistingCardPicker(cards: cards),
  );
  if (card == null || !context.mounted) return;

  // A local card has no server draft to append to — the items accumulate
  // here and the draft is created in one piece when the sale completes.
  // Calling the network for it would 404 at flush time.
  if (!card.orderId.startsWith('local:')) {
    try {
      await OrderRepositoryImpl().addOrderItems(
        orderId: card.orderId,
        items: items.map(_saleEntity).toList(),
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      showErrorMessage(context, e.message);
      return;
    } catch (e) {
      if (!context.mounted) return;
      showErrorMessage(
        context,
        context.l10n
            .t('Failed to add to existing card: {v1}')
            .replaceAll('{v1}', (e).toString()),
      );
      return;
    }
  }

  final updatedCard = await CartStore.instance.appendToCard(card.id, items);
  if (!context.mounted || updatedCard == null) return;
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CartCardScreen(card: updatedCard)));
}

SaleItemEntity _saleEntity(CartItemEntity e) => SaleItemEntity(
  productId: e.productId,
  productName: e.productName,
  imageUrl: e.imageUrl,
  unitPrice: e.unitPrice,
  quantity: e.quantity,
  size: e.size,
  color: e.color,
  category: e.category,
);

String _random5() {
  final rand = Random();
  return (10000 + rand.nextInt(90000)).toString();
}

/// Asks whether the items go on a brand-new cart card or an existing one.
class AddToCartChoiceDialog extends StatelessWidget {
  final String productName;

  const AddToCartChoiceDialog({super.key, required this.productName});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add to Cart',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            context,
            icon: Icons.add_card,
            title: context.l10n.t('New Card'),
            subtitle: context.l10n.t('Create a new cart card for these items'),
            choice: AddToCartChoice.newCard,
          ),
          const SizedBox(height: 10),
          _option(
            context,
            icon: Icons.folder_open,
            title: context.l10n.t('Existing Card'),
            subtitle: context.l10n.t(
              'Load an old card and add items to it (merge categories)',
            ),
            choice: AddToCartChoice.existingCard,
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required AddToCartChoice choice,
  }) {
    final p = ctx.palette;
    return InkWell(
      onTap: () => Navigator.of(ctx).pop(choice),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.selectionTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: p.accentText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet list of existing cart cards to add items into.
class ExistingCardPicker extends StatefulWidget {
  final List<CartCardEntity> cards;

  const ExistingCardPicker({super.key, required this.cards});

  @override
  State<ExistingCardPicker> createState() => _ExistingCardPickerState();
}

class _ExistingCardPickerState extends State<ExistingCardPicker> {
  AppPalette get _p => context.palette;
  Color get _mutedColor => _p.textSecondary;
  Color get _accentColor => _p.primary;
  Color get _titleColor => _p.textPrimary;
  Color get _borderColor => _p.border;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.t('Existing Cards'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, size: 20, color: _mutedColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: widget.cards.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final card = widget.cards[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(card),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _p.selectionTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              color: _accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.l10n
                                      .t('{v1} items')
                                      .replaceAll(
                                        '{v1}',
                                        (card.totalQuantity).toString(),
                                      ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _titleColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card.items
                                      .take(3)
                                      .map((e) => e.productName)
                                      .join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PriceText(
                            card.total,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
