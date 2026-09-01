import 'package:flutter/material.dart';

class ProductVariant {
  final String size;
  final String color;
  final int quantity;
  final double price;

  const ProductVariant({
    this.size = '',
    this.color = '',
    this.quantity = 0,
    this.price = 0,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      size: (json['size'] as String?)?.trim() ?? '',
      color: (json['color'] as String?)?.trim() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CatalogProduct {
  final String id;
  final String name;
  final String brand;
  final String sku;
  final double price;
  final int stock;
  final bool isSet;
  final String category;
  final String packageId;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final List<ProductVariant> variants;

  const CatalogProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.sku,
    required this.price,
    required this.stock,
    this.isSet = false,
    required this.category,
    this.packageId = '',
    required this.icon,
    required this.color,
    this.imageUrl,
    this.variants = const [],
  });

  List<String> get sizes => variants
      .map((v) => v.size)
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();

  List<String> get colors => variants
      .map((v) => v.color)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList();

  static const List<Color> _palette = [
    Color(0xFF6D28D9),
    Color(0xFF0EA5E9),
    Color(0xFF16A34A),
    Color(0xFFEA580C),
    Color(0xFFE11D48),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFCA8A04),
  ];

  static Color colorFor(String key) {
    if (key.isEmpty) return _palette.last;
    return _palette[key.hashCode.abs() % _palette.length];
  }

  static IconData iconFor(String key) {
    if (key.isEmpty) return Icons.inventory_2;
    const icons = [
      Icons.headphones,
      Icons.earbuds,
      Icons.flash_on,
      Icons.mouse,
      Icons.speaker,
      Icons.phone_android,
      Icons.watch,
      Icons.laptop,
      Icons.camera_alt,
      Icons.tv,
    ];
    return icons[key.hashCode.abs() % icons.length];
  }
}
