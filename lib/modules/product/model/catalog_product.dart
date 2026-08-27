import 'package:flutter/material.dart';

class CatalogProduct {
  final String id;
  final String name;
  final String brand;
  final String sku;
  final double price;
  final int stock;
  final bool isSet;
  final String category;
  final IconData icon;
  final Color color;
  final String? imageUrl;

  const CatalogProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.sku,
    required this.price,
    required this.stock,
    this.isSet = false,
    required this.category,
    required this.icon,
    required this.color,
    this.imageUrl,
  });
}
