import 'package:flutter/material.dart';

class Category {
  final String id;
  final String inventoryId;
  final String type;
  final String name;
  final int packageCount;
  final int packageLimit;
  final String description;
  final String createdDate;
  final DateTime? createdAt;
  final bool active;
  final Color iconColor;
  final IconData icon;
  final String? imageUrl;

  const Category({
    required this.id,
    this.inventoryId = '',
    this.type = '',
    required this.name,
    required this.packageCount,
    required this.packageLimit,
    required this.description,
    required this.createdDate,
    this.createdAt,
    required this.active,
    required this.iconColor,
    required this.icon,
    this.imageUrl,
  });
}
