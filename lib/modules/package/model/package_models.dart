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
  final String code;
  final String name;
  final String spec;
  final int quantity;
  final String location;
  final StockStatus status;
  final String? imageUrl;

  const Package({
    required this.code,
    required this.name,
    required this.spec,
    required this.quantity,
    required this.location,
    required this.status,
    this.imageUrl,
  });
}
