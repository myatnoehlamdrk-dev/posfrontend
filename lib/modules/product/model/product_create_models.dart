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

class ProductSearchResult {
  final String id;
  final String name;
  final String brand;
  final String sku;
  final String size;
  final String color;
  final int stock;
  final List<Map<String, dynamic>> variants;
  final String supplierId;
  final String supplierName;
  final String supplierContact;
  final String supplierAddress;
  final String imageUrl;

  const ProductSearchResult({
    required this.id,
    required this.name,
    this.brand = '',
    this.sku = '',
    this.size = '',
    this.color = '',
    this.stock = 0,
    this.variants = const [],
    this.supplierId = '',
    this.supplierName = '',
    this.supplierContact = '',
    this.supplierAddress = '',
    this.imageUrl = '',
  });

  factory ProductSearchResult.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variants'];
    List<Map<String, dynamic>> variantList = [];
    if (rawVariants is List) {
      variantList = rawVariants.whereType<Map<String, dynamic>>().toList();
    }
    return ProductSearchResult(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      size: json['size'] as String? ?? '',
      color: json['color'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      variants: variantList,
      supplierId: (json['supplierId'] ?? '').toString(),
      supplierName: json['supplierName'] as String? ?? '',
      supplierContact: json['supplierContact'] as String? ?? '',
      supplierAddress: json['supplierAddress'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
    );
  }
}

class PendingPurchaseItem {
  final String id;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String date;
  final String supplierId;
  final String supplierName;
  final String notes;

  const PendingPurchaseItem({
    required this.id,
    required this.productName,
    this.quantity = 0,
    this.unitPrice = 0,
    this.totalPrice = 0,
    this.date = '',
    this.supplierId = '',
    this.supplierName = '',
    this.notes = '',
  });

  factory PendingPurchaseItem.fromJson(Map<String, dynamic> json) {
    return PendingPurchaseItem(
      id: (json['id'] ?? '').toString(),
      productName: json['productName'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: json['unitPrice'] as int? ?? 0,
      totalPrice: json['totalPrice'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      supplierId: (json['supplierId'] ?? '').toString(),
      supplierName: json['supplierName'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
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
  final String supplierId;
  final String supplierName;
  final String supplierContact;
  final String supplierSince;
  final String supplierAddress;
  final String imageDeleteUrl;
  final String purchaseItemId;

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
    this.supplierId = '',
    this.supplierName = '',
    this.supplierContact = '',
    this.supplierSince = '',
    this.supplierAddress = '',
    this.imageDeleteUrl = '',
    this.purchaseItemId = '',
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
        if (supplierId.isNotEmpty) 'supplierId': int.tryParse(supplierId),
        'supplierName': supplierName.isEmpty ? null : supplierName,
        'supplierContact': supplierContact.isEmpty ? null : supplierContact,
        'supplierSince': supplierSince.isEmpty ? null : supplierSince,
        'supplierAddress': supplierAddress.isEmpty ? null : supplierAddress,
        'imageDeleteUrl': imageDeleteUrl.isEmpty ? null : imageDeleteUrl,
        'packageId': packageId.isEmpty ? null : int.tryParse(packageId),
        'purchaseItemId': purchaseItemId.isEmpty ? null : int.tryParse(purchaseItemId),
      };
}
