import 'package:equatable/equatable.dart';

class ProductVariantEntity extends Equatable {
  final String id;
  final String size;
  final String color;
  final int quantity;
  final double price;

  const ProductVariantEntity({
    this.id = '',
    this.size = '',
    this.color = '',
    this.quantity = 0,
    this.price = 0,
  });

  @override
  List<Object> get props => [id, size, color, quantity, price];
}
