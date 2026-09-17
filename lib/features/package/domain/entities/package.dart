import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

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

class PackageEntity extends Equatable {
  final String id;
  final String categoryId;
  final String code;
  final String name;
  final String spec;
  final String location;
  final String createdBy;
  final String updatedBy;
  final String createdAt;
  final String updatedAt;
  final int quantity;
  final int productLimit;
  final StockStatus status;
  final String? imageUrl;
  final List<String> productImages;

  const PackageEntity({
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
    this.productImages = const [],
    this.createdBy = '',
    this.updatedBy = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  @override
  List<Object?> get props => [id, name, code, categoryId];
}
