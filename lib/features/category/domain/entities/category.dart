import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String inventoryId;
  final String type;
  final String name;
  final String description;
  final int packageCount;
  final int packageLimit;
  final String createdDate;
  final String createdBy;
  final String updatedBy;
  final String updatedAt;
  final bool active;
  final String? imageUrl;
  final List<String> productImages;
  final Color? iconColor;
  final IconData? icon;

  const Category({
    required this.id,
    this.inventoryId = '',
    this.type = '',
    required this.name,
    this.description = '',
    this.packageCount = 0,
    this.packageLimit = 0,
    this.createdDate = '',
    this.createdBy = '',
    this.updatedBy = '',
    this.updatedAt = '',
    this.active = true,
    this.imageUrl,
    this.productImages = const [],
    this.iconColor,
    this.icon,
  });

  @override
  List<Object?> get props => [id, name, type, active];
}
