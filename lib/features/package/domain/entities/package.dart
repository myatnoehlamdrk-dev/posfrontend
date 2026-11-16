import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';

enum StockStatus { highStock, midStock, lowStock, outOfStock }

Color stockBg(AppPalette p, StockStatus s) {
  switch (s) {
    case StockStatus.highStock:
      return p.successBg;
    case StockStatus.midStock:
      return p.infoBg;
    case StockStatus.lowStock:
      return p.warningBg;
    case StockStatus.outOfStock:
      return p.dangerBg;
  }
}

Color stockFg(AppPalette p, StockStatus s) {
  switch (s) {
    case StockStatus.highStock:
      return p.successFg;
    case StockStatus.midStock:
      return p.infoFg;
    case StockStatus.lowStock:
      return p.warningFg;
    case StockStatus.outOfStock:
      return p.dangerFg;
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
