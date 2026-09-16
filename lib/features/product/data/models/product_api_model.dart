import 'package:posfrontend/features/product/domain/entities/product_variant.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';

class ProductApiModel {
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
  final List<ProductVariantApiModel> variants;
  final String createdBy;

  const ProductApiModel({
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

  factory ProductApiModel.fromJson(Map<String, dynamic> json) {
    final variants = json['variants'];
    final variantList = variants is List ? variants : const [];
    return ProductApiModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isSet: json['isSet'] == true,
      category: json['category']?.toString() ?? '',
      packageId: json['packageId']?.toString() ?? '',
      imageUrl: json['image']?.toString().trim(),
      variants: variantList
          .map((v) => ProductVariantApiModel.fromJson(v as Map<String, dynamic>))
          .toList(),
      createdBy: json['createdBy']?.toString() ?? '',
    );
  }

  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      name: name,
      brand: brand,
      sku: sku,
      price: price,
      stock: stock,
      isSet: isSet,
      category: category,
      packageId: packageId,
      imageUrl: imageUrl,
      variants: variants.map((v) => v.toEntity()).toList(),
      createdBy: createdBy,
    );
  }
}

class ProductVariantApiModel {
  final String size;
  final String color;
  final int quantity;
  final double price;

  const ProductVariantApiModel({
    this.size = '',
    this.color = '',
    this.quantity = 0,
    this.price = 0,
  });

  factory ProductVariantApiModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantApiModel(
      size: (json['size'] as String?)?.trim() ?? '',
      color: (json['color'] as String?)?.trim() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  ProductVariantEntity toEntity() {
    return ProductVariantEntity(
      size: size,
      color: color,
      quantity: quantity,
      price: price,
    );
  }
}
