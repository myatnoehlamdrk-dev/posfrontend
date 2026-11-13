import 'package:equatable/equatable.dart';

class ProductVariantEntity extends Equatable {
  final String id;
  final String size;
  final String color;
  final int quantity;
  final double price;

  /// Original buying price of one unit. Zero means "use the product-level
  /// cost price", which is how profit falls back for variants that never had
  /// a cost stored.
  final double costPrice;

  const ProductVariantEntity({
    this.id = '',
    this.size = '',
    this.color = '',
    this.quantity = 0,
    this.price = 0,
    this.costPrice = 0,
  });

  @override
  List<Object> get props => [id, size, color, quantity, price, costPrice];
}
