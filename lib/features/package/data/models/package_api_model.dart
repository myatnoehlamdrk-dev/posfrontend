import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';

class PackageApiModel {
  final String id;
  final String categoryId;
  final String code;
  final String name;
  final String spec;
  final String location;
  final int quantity;
  final int productLimit;
  final StockStatus status;
  final String? imageUrl;
  final List<String> productImages;
  final String createdBy;
  final String updatedBy;
  final String createdAt;
  final String updatedAt;

  const PackageApiModel({
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

  factory PackageApiModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final rawImages = json['productImages'];
    final productImages = (rawImages is List)
        ? rawImages
            .whereType<String>()
            .map(resolveMediaUrl)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];
    return PackageApiModel(
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
      productImages: productImages,
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  PackageEntity toEntity() {
    return PackageEntity(
      id: id,
      categoryId: categoryId,
      code: code,
      name: name,
      spec: spec,
      quantity: quantity,
      productLimit: productLimit,
      location: location,
      status: status,
      imageUrl: imageUrl,
      productImages: productImages,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'description': spec,
        'amountOfProduct': quantity,
        'productLimit': productLimit,
        'location': location,
        'stockStatus': stockStatusToString(status),
        'productImages': productImages,
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
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

String stockStatusLabel(StockStatus s) {
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
