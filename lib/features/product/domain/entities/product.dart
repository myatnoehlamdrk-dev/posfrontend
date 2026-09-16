import 'package:equatable/equatable.dart';
import 'package:posfrontend/features/product/domain/entities/product_variant.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String brand;
  final String sku;
  final double price;
  final int stock;
  final bool isSet;
  final String category;
  final String packageId;
  final String? imageUrl;
  final List<ProductVariantEntity> variants;
  final String createdBy;

  const ProductEntity({
    required this.id,
    required this.name,
    this.brand = '',
    this.sku = '',
    this.price = 0,
    this.stock = 0,
    this.isSet = false,
    this.category = '',
    this.packageId = '',
    this.imageUrl,
    this.variants = const [],
    this.createdBy = '',
  });

  List<String> get sizes => variants
      .map((v) => v.size)
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();

  List<String> get colors => variants
      .map((v) => v.color)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList();

  @override
  List<Object?> get props => [id, name, brand, sku, price, stock, category, variants];
}
