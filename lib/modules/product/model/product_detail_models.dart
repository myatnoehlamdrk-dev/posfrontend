import 'package:posfrontend/core/extensions/map_json_extensions.dart';

class ProductVariant {
  final String id;
  final String size;
  final String color;
  final double price;
  final int quantity;

  const ProductVariant({
    required this.id,
    required this.size,
    required this.color,
    required this.price,
    required this.quantity,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      size: json.str('size'),
      color: json.str('color'),
      price: json.decimal('price'),
      quantity: json.integer('quantity'),
    );
  }
}

class ProductDetail {
  final String id;
  final String name;
  final String categoryName;
  final String sku;
  final String isBundle;
  final String brand;
  final String color;
  final String size;
  final String packageId;
  final String packageName;
  final String inventoryId;
  final String inventoryType;
  final String status;
  final double price;
  final int stockAvailable;
  final int stockReserved;
  final int reorderLevel;
  final int minStock;
  final int maxCapacity;
  final String stockStatus;
  final String supplierId;
  final String supplierName;
  final String supplierContact;
  final String contractNumber;
  final String supplierSince;
  final String supplierAddress;
  final String? imageUrl;
  final String? imageDeleteUrl;
  final List<ProductVariant> variants;
  final String createdBy;
  final String updatedBy;
  final String createdAt;
  final String updatedAt;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.sku,
    required this.isBundle,
    required this.brand,
    required this.color,
    required this.size,
    required this.packageId,
    required this.packageName,
    required this.inventoryId,
    required this.inventoryType,
    required this.status,
    required this.price,
    required this.stockAvailable,
    required this.stockReserved,
    required this.reorderLevel,
    required this.minStock,
    required this.maxCapacity,
    required this.stockStatus,
    required this.supplierId,
    required this.supplierName,
    required this.supplierContact,
    required this.contractNumber,
    required this.supplierSince,
    required this.supplierAddress,
    this.imageUrl,
    this.imageDeleteUrl,
    this.variants = const [],
    this.createdBy = '',
    this.updatedBy = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final variants = json['variants'];
    final variantList = variants is List ? variants : const [];
    final price = variantList.isNotEmpty
        ? (variantList.first['price'] ?? 0).toDouble()
        : 0.0;
    final parsedVariants = variantList
        .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
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

    return ProductDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed',
      categoryName: json.str('category'),
      sku: json.str('sku', '—'),
      isBundle: json.boolean('isSet') ? 'Yes' : 'No',
      brand: json.str('brand', '—'),
      color: json.str('color', '—'),
      size: size?.toString() ?? '—',
      packageId: json.str('packageId', '—'),
      packageName: json.str('packageName', '—'),
      inventoryId: '—',
      inventoryType: json.str('inventoryType', '—'),
      status: 'Active',
      price: price,
      stockAvailable: stock,
      stockReserved: 0,
      reorderLevel: 10,
      minStock: stock,
      maxCapacity: stock > 0 ? stock : 100,
      stockStatus: stockStatus,
      supplierId: json.str('supplierId', '—'),
      supplierName: json.str('supplierName', '—'),
      supplierContact: json.str('supplierContact', '—'),
      contractNumber: json.str('contractNumber', '—'),
      supplierSince: json.str('supplierSince', '—'),
      supplierAddress: json.str('supplierAddress', '—'),
      imageUrl: image != null && image.isNotEmpty ? image : null,
      imageDeleteUrl: (json['imageDeleteUrl'] as String?)?.trim(),
      variants: parsedVariants,
      createdBy: json.str('createdBy'),
      updatedBy: json.str('updatedBy'),
      createdAt: json.str('createdAt'),
      updatedAt: json.str('updatedAt'),
    );
  }
}
