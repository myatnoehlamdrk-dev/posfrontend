import 'package:flutter/material.dart';

enum StockStatus { highStock, midStock, lowStock, outOfStock }

Color stockBg(StockStatus s) {
  switch (s) {
    case StockStatus.highStock:
      return const Color(0xFFDCFCE7);
    case StockStatus.midStock:
      return const Color(0xFFDBEAFE);
    case StockStatus.lowStock:
      return const Color(0xFFFEF3C7);
    case StockStatus.outOfStock:
      return const Color(0xFFFEE2E2);
  }
}

Color stockFg(StockStatus s) {
  switch (s) {
    case StockStatus.highStock:
      return const Color(0xFF16A34A);
    case StockStatus.midStock:
      return const Color(0xFF2563EB);
    case StockStatus.lowStock:
      return const Color(0xFFD97706);
    case StockStatus.outOfStock:
      return const Color(0xFFDC2626);
  }
}

String stockLabel(StockStatus s) {
  switch (s) {
    case StockStatus.highStock:
      return 'High Stock';
    case StockStatus.midStock:
      return 'Mid-Cap Stock';
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
    case 'high stock':
    case 'high_stock':
    case 'optimal':
    case 'overstock':
      return StockStatus.highStock;
    case 'mid stock':
    case 'mid_stock':
    case 'mid-cap stock':
    case 'mid_cap_stock':
      return StockStatus.midStock;
    case 'low stock':
    case 'low_stock':
      return StockStatus.lowStock;
    case 'no stock':
    case 'out of stock':
    case 'out_of_stock':
    case 'critical':
      return StockStatus.outOfStock;
    default:
      return StockStatus.highStock;
  }
}

String stockStatusToString(StockStatus status) {
  switch (status) {
    case StockStatus.highStock:
      return 'High Stock';
    case StockStatus.midStock:
      return 'Mid-Cap Stock';
    case StockStatus.lowStock:
      return 'Low Stock';
    case StockStatus.outOfStock:
      return 'Out of Stock';
  }
}
