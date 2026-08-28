import 'package:flutter/material.dart';

enum StockStatus { inStock, lowStock, outOfStock }

Color stockBg(StockStatus s) {
  switch (s) {
    case StockStatus.inStock:
      return const Color(0xFFDCFCE7);
    case StockStatus.lowStock:
      return const Color(0xFFFEF3C7);
    case StockStatus.outOfStock:
      return const Color(0xFFFEE2E2);
  }
}

Color stockFg(StockStatus s) {
  switch (s) {
    case StockStatus.inStock:
      return const Color(0xFF16A34A);
    case StockStatus.lowStock:
      return const Color(0xFFD97706);
    case StockStatus.outOfStock:
      return const Color(0xFFDC2626);
  }
}

String stockLabel(StockStatus s) {
  switch (s) {
    case StockStatus.inStock:
      return 'In Stock';
    case StockStatus.lowStock:
      return 'Low Stock';
    case StockStatus.outOfStock:
      return 'Out of Stock';
  }
}

class Package {
  final String id;
  final String categoryId;
  final String code;
  final String name;
  final String spec;
  final int quantity;
  final int productLimit;
  final String location;
  final StockStatus status;
  final String? imageUrl;

  const Package({
    required this.id,
    this.categoryId = '',
    required this.code,
    required this.name,
    required this.spec,
      required this.quantity,
      required this.productLimit,
      required this.location,
    required this.status,
    this.imageUrl,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    return Package(
      id: id,
      categoryId: json['categoryId']?.toString() ?? '',
      code: 'PKG-$id',
      name: json['name'] ?? '',
      spec: json['description'] ?? '',
      quantity: json['amountOfProduct'] is int
          ? json['amountOfProduct'] as int
          : int.tryParse(json['amountOfProduct']?.toString() ?? '') ?? 0,
      productLimit: json['productLimit'] is int
          ? json['productLimit'] as int
          : int.tryParse(json['productLimit']?.toString() ?? '') ?? 0,
      location: json['location'] ?? '',
      status: stockStatusFromString(json['stockStatus']),
    );
  }
}

StockStatus stockStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'low stock':
    case 'low_stock':
      return StockStatus.lowStock;
    case 'no stock':
    case 'out of stock':
    case 'out_of_stock':
    case 'critical':
      return StockStatus.outOfStock;
    default:
      return StockStatus.inStock;
  }
}

String stockStatusToString(StockStatus status) {
  switch (status) {
    case StockStatus.lowStock:
      return 'Low Stock';
    case StockStatus.outOfStock:
      return 'No Stock';
    case StockStatus.inStock:
      return 'Optimal';
  }
}
