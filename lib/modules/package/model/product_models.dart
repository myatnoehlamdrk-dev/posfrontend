import 'package:flutter/material.dart';

class Product {
  final String name;
  final String description;
  final int quantity;
  final IconData icon;

  const Product({
    required this.name,
    required this.description,
    required this.quantity,
    this.icon = Icons.inventory_2,
  });
}
