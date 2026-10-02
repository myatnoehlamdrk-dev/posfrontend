import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_card_entity.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_item_entity.dart';

/// Builds a cart card out of one row of the orders table.
///
/// Returns null for anything that is not a draft order, or that has no usable
/// line items: a card with no items cannot take a merge, and a completed order
/// cannot take new ones.
///
/// Lived in the cart screen as a private method until the products screen
/// needed the same list for `Add to Cart` → `Existing Card`. Two copies of this
/// mapping is how the two screens started disagreeing about what an existing
/// card is, so it lives here now and both call it.
CartCardEntity? cartCardFromOrder(Map<String, dynamic> json) {
  if ((json['status']?.toString() ?? '') != 'draft') return null;

  final orderId = json['id']?.toString() ?? '';
  if (orderId.isEmpty) return null;

  final rawItems = json['items'];
  if (rawItems is! List || rawItems.isEmpty) return null;

  final items = <CartItemEntity>[];
  for (final raw in rawItems) {
    if (raw is! Map<String, dynamic>) continue;
    final quantity = (raw['quantity'] as num?)?.toInt() ?? 0;
    if (quantity <= 0) continue;
    final size = (raw['size'] as String?)?.trim();
    final color = (raw['color'] as String?)?.trim();
    final category = (raw['category'] as String?)?.trim();
    items.add(
      CartItemEntity(
        productId: raw['productId']?.toString() ?? '',
        productName: raw['productName']?.toString() ?? '',
        imageUrl: resolveMediaUrl(raw['imageUrl']?.toString()),
        unitPrice: (raw['unitPrice'] as num?)?.toDouble() ?? 0.0,
        quantity: quantity,
        size: size != null && size.isNotEmpty ? size : null,
        color: color != null && color.isNotEmpty ? color : null,
        category: category ?? '',
      ),
    );
  }

  if (items.isEmpty) return null;

  return CartCardEntity(
    id: 'backend-$orderId',
    orderId: orderId,
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    items: items,
  );
}

/// The values that mark an order as belonging to the signed-in user.
///
/// The orders endpoint has no shop filter, so every shop's drafts come back in
/// one page. Matching on the session's own identity is what keeps one shop's
/// cards out of another's cart.
Set<String> cartOwnerKeys({
  String? userId,
  String? fullName,
  String? email,
}) {
  return {
    for (final value in [userId, fullName, email])
      if (value != null && value.trim().isNotEmpty) value.trim().toLowerCase(),
  };
}

/// Whether one order row belongs to [ownerKeys].
///
/// An order with no owner field at all is kept: there is nothing to compare it
/// against, and dropping those would empty the cart outright on a backend that
/// does not echo ownership. A row that *does* name an owner is only kept when
/// that owner is this user.
bool cartOrderBelongsTo(Map<String, dynamic> order, Set<String> ownerKeys) {
  if (ownerKeys.isEmpty) return true;

  String? read(String key) {
    final value = order[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text.toLowerCase();
  }

  // `userName` is what this app posts when it creates the draft;
  // `createdBy` is what the orders endpoint echoes back. Both are checked so
  // this keeps working whichever the backend actually returns.
  final owners = [
    read('userName'),
    read('createdBy'),
    read('user_name'),
    read('created_by'),
    read('userId'),
    read('user_id'),
  ].whereType<String>().toSet();

  if (owners.isEmpty) return true;
  return owners.any(ownerKeys.contains);
}