import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/map_json_extensions.dart';

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
  final String categoryId;
  final String packageId;
  final bool isSet;
  final String inventoryType;

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
    this.categoryId = '',
    this.packageId = '',
    this.isSet = false,
    this.inventoryType = 'self',
  });

  factory ProductSearchResult.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variants'];
    List<Map<String, dynamic>> variantList = [];
    if (rawVariants is List) {
      variantList = rawVariants.whereType<Map<String, dynamic>>().toList();
    }
    return ProductSearchResult(
      id: json.str('id'),
      name: json.str('name'),
      brand: json.str('brand'),
      sku: json.str('sku'),
      size: json.str('size'),
      color: json.str('color'),
      stock: json.integer('stock'),
      variants: variantList,
      supplierId: json.str('supplierId'),
      supplierName: json.str('supplierName'),
      supplierContact: json.str('supplierContact'),
      supplierAddress: json.str('supplierAddress'),
      imageUrl: json.str('image'),
      categoryId: json.str('categoryId'),
      packageId: json.str('packageId'),
      isSet: json.boolean('isSet'),
      inventoryType: json.str('inventoryType', 'self'),
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
      id: json.str('id'),
      productName: json.str('productName'),
      quantity: json.integer('quantity'),
      unitPrice: json.integer('unitPrice'),
      totalPrice: json.integer('totalPrice'),
      date: json.str('date'),
      supplierId: json.str('supplierId'),
      supplierName: json.str('supplierName'),
      notes: json.str('notes'),
    );
  }
}

class PackageOption {
  final String id;
  final String name;
  const PackageOption({required this.id, required this.name});
}

class ProductCreateVariant {
  final String size;
  final String color;
  final int quantity;
  final double price;

  ProductCreateVariant({
    this.size = '',
    this.color = '',
    this.quantity = 0,
    this.price = 0.0,
  });

  ProductCreateVariant copyWith({
    String? size,
    String? color,
    int? quantity,
    double? price,
  }) {
    return ProductCreateVariant(
      size: size ?? this.size,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductCreateVariant &&
        other.size == size &&
        other.color == color &&
        other.quantity == quantity &&
        other.price == price;
  }

  @override
  int get hashCode => Object.hash(size, color, quantity, price);

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
  final List<ProductCreateVariant> variants;
  final int? stock;
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
    this.stock,
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
        'stock': stock ?? totalStock,
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
