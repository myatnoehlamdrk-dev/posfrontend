import 'package:posfrontend/features/cart/domain/entities/cart_item_entity.dart';

class CartCardEntity {
  final String id;
  final String orderId;
  final DateTime createdAt;
  final List<CartItemEntity> items;

  const CartCardEntity({
    required this.id,
    this.orderId = '',
    required this.createdAt,
    required this.items,
  });

  double get total => items.fold(0.0, (sum, e) => sum + e.subtotal);

  int get totalQuantity =>
      items.fold(0, (sum, e) => sum + e.quantity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory CartCardEntity.fromJson(Map<String, dynamic> json) {
    return CartCardEntity(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      items: (json['items'] as List? ?? const [])
          .map((e) => CartItemEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}