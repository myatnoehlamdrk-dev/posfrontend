import 'package:posfrontend/core/extensions/map_json_extensions.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/product/domain/entities/product_variant.dart';
import 'package:posfrontend/features/product/domain/entities/product_detail.dart';

class ProductDetailApiModel {
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
  final List<ProductVariantDetailApiModel> variants;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  const ProductDetailApiModel({
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

  factory ProductDetailApiModel.fromJson(Map<String, dynamic> json) {
    final variants = json['variants'];
    final variantList = variants is List ? variants : const [];
    final price = variantList.isNotEmpty
        ? (variantList.first['price'] ?? 0).toDouble()
        : 0.0;
    final parsedVariants = variantList
        .map((v) => ProductVariantDetailApiModel.fromJson(v as Map<String, dynamic>))
        .toList();
    final stock = json.integer('stock');
    final size = (json['size'] as String?)?.isNotEmpty == true
        ? json['size'] as String
        : (variantList.isNotEmpty ? (variantList.first['size'] ?? '') : '');
    final image = (json['image'] as String?)?.trim();

    final stockStatus = stock == 0
        ? 'Out of Stock'
        : (stock < 10
            ? 'Low Stock'
            : (stock <= 20 ? 'Mid-Cap Stock' : 'High Stock'));

    return ProductDetailApiModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed',
      categoryName: json.str('category'),
      sku: json.str('sku', '—'),
      isBundle: json.boolean('isSet'),
      brand: json.str('brand', '—'),
      color: json.str('color', '—'),
      size: size?.toString() ?? '—',
      packageId: json.str('packageId', '—'),
      packageName: json.str('packageName', '—'),
      inventoryType: json.str('inventoryType', '—'),
      price: price,
      stockAvailable: stock,
      stockStatus: stockStatus,
      supplierId: json.str('supplierId', '—'),
      supplierName: json.str('supplierName', '—'),
      supplierContact: json.str('supplierContact', '—'),
      imageUrl: resolveMediaUrl(image),
      variants: parsedVariants,
      createdBy: json.str('createdBy'),
      createdAt: json.str('createdAt'),
      updatedAt: json.str('updatedAt'),
    );
  }

  ProductDetailEntity toEntity() {
    return ProductDetailEntity(
      id: id,
      name: name,
      categoryName: categoryName,
      sku: sku,
      isBundle: isBundle ? 'Yes' : 'No',
      brand: brand,
      color: color,
      size: size,
      packageId: packageId,
      packageName: packageName,
      inventoryType: inventoryType,
      price: price,
      stockAvailable: stockAvailable,
      stockStatus: stockStatus,
      supplierId: supplierId,
      supplierName: supplierName,
      supplierContact: supplierContact,
      imageUrl: imageUrl,
      variants: variants.map((v) => v.toEntity()).toList(),
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ProductVariantDetailApiModel {
  final String id;
  final String size;
  final String color;
  final double price;
  final int quantity;

  const ProductVariantDetailApiModel({
    required this.id,
    this.size = '',
    this.color = '',
    this.price = 0,
    this.quantity = 0,
  });

  factory ProductVariantDetailApiModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantDetailApiModel(
      id: json['id']?.toString() ?? '',
      size: json.str('size'),
      color: json.str('color'),
      price: json.decimal('price'),
      quantity: json.integer('quantity'),
    );
  }

  ProductVariantEntity toEntity() {
    return ProductVariantEntity(
      id: id,
      size: size,
      color: color,
      price: price,
      quantity: quantity,
    );
  }
}
