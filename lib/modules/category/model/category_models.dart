import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final int packageCount;
  final String description;
  final String createdDate;
  final bool active;
  final Color iconColor;
  final IconData icon;
  final String? imageUrl;

  const Category({
    required this.id,
    required this.name,
    required this.packageCount,
    required this.description,
    required this.createdDate,
    required this.active,
    required this.iconColor,
    required this.icon,
    this.imageUrl,
  });
}
