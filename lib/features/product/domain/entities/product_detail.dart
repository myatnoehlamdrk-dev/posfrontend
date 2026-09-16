import 'package:equatable/equatable.dart';
import 'package:posfrontend/features/product/domain/entities/product_variant.dart';

class ProductDetailEntity extends Equatable {
  final String id;
  final String name;
  final String categoryName;
  final String sku;
  final bool isBundle;
  final String brand;
  final String color;
  final String size;
  final String packageId;
  final String packageName;
  final String inventoryType;
  final double price;
  final int stockAvailable;
  final String stockStatus;
  final String supplierId;
  final String supplierName;
  final String supplierContact;
  final String? imageUrl;
  final List<ProductVariantEntity> variants;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  const ProductDetailEntity({
    required this.id,
    required this.name,
    this.categoryName = '',
    this.sku = '',
    this.isBundle = false,
    this.brand = '',
    this.color = '',
    this.size = '',
    this.packageId = '',
    this.packageName = '',
    this.inventoryType = '',
    this.price = 0,
    this.stockAvailable = 0,
    this.stockStatus = '',
    this.supplierId = '',
    this.supplierName = '',
    this.supplierContact = '',
    this.imageUrl,
    this.variants = const [],
    this.createdBy = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  @override
  List<Object?> get props => [id, name, sku, price, stockAvailable];
}
