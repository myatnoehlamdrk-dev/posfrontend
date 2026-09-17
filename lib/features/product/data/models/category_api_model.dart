import 'package:posfrontend/features/product/domain/entities/category.dart';

class CategoryApiModel {
  final String id;
  final String? inventoryId;
  final String? type;
  final String name;
  final int? packageCount;
  final int? packageLimit;
  final String? description;
  final bool active;

  const CategoryApiModel({
    required this.id,
    required this.name,
    this.inventoryId,
    this.type,
    this.packageCount,
    this.packageLimit,
    this.description,
    this.active = true,
  });

  factory CategoryApiModel.fromJson(Map<String, dynamic> json) {
    return CategoryApiModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      inventoryId: json['inventoryId']?.toString(),
      type: json['type']?.toString(),
      packageCount: (json['packageCount'] as num?)?.toInt(),
      packageLimit: (json['packageLimit'] as num?)?.toInt(),
      description: json['description']?.toString(),
      active: json['active'] != false,
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      inventoryId: inventoryId,
      type: type,
      packageCount: packageCount,
      packageLimit: packageLimit,
      description: description,
      active: active,
    );
  }
}
