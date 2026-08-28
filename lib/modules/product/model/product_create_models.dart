import 'package:flutter/material.dart';

class ProductColorOption {
  final String label;
  final Color color;
  const ProductColorOption(this.label, this.color);
}

class SupplierOption {
  final String id;
  final String name;
  const SupplierOption({required this.id, required this.name});
}

class PackageOption {
  final String id;
  final String name;
  const PackageOption({required this.id, required this.name});
}

class ProductVariant {
  final String size;
  final String color;
  final int quantity;
  final double price;

  ProductVariant({
    this.size = '',
    this.color = '',
    this.quantity = 0,
    this.price = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'size': size,
        'color': color,
        'quantity': quantity,
        'price': price,
      };
}

class ProductCreateRequest {
  final bool isSet;
  final String name;
  final String imageUrl;
  final String brand;
  final String inventoryType;
  final String categoryId;
  final String packageId;
  final List<ProductVariant> variants;
  final String sku;
  final String supplierName;

  const ProductCreateRequest({
    this.isSet = false,
    this.name = '',
    this.imageUrl = '',
    this.brand = '',
    this.inventoryType = 'self',
    this.categoryId = '',
    this.packageId = '',
    this.variants = const [],
    this.sku = '',
    this.supplierName = '',
  });

  int get totalStock =>
      variants.fold(0, (sum, v) => sum + (v.quantity > 0 ? v.quantity : 0));

  Map<String, dynamic> toJson() => {
        'isSet': isSet,
        'name': name,
        'image': imageUrl.isEmpty ? null : imageUrl,
        'brand': brand.isEmpty ? null : brand,
        'sku': sku.isEmpty ? null : sku,
        'stock': totalStock,
        if (variants.isNotEmpty) 'size': variants.first.size,
        if (variants.isNotEmpty) 'color': variants.first.color,
        'variants': variants.map((v) => v.toJson()).toList(),
        'supplierName': supplierName.isEmpty ? null : supplierName,
        'packageId': packageId.isEmpty ? null : int.tryParse(packageId),
      };
}
