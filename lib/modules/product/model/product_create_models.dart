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

class ProductCreateRequest {
  final String productId;
  final bool isSet;
  final String name;
  final String imageUrl;
  final String brand;
  final String categoryId;
  final int stock;
  final double price;
  final String sku;
  final String sizeType;
  final List<String> colors;
  final String supplierId;
  final String packageId;
  final String createdByStaffId;

  const ProductCreateRequest({
    required this.productId,
    this.isSet = false,
    this.name = '',
    this.imageUrl = '',
    this.brand = '',
    this.categoryId = '',
    this.stock = 0,
    this.price = 0.0,
    this.sku = '',
    this.sizeType = '',
    this.colors = const [],
    this.supplierId = '',
    this.packageId = '',
    this.createdByStaffId = '',
  });
}
