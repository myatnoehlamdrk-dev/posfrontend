import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';

class CategoryApiModel {
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

  const CategoryApiModel({
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
  });

  factory CategoryApiModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['productImages'];
    final productImages = (rawImages is List)
        ? rawImages
            .whereType<String>()
            .map(resolveMediaUrl)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];

    return CategoryApiModel(
      id: json['id']?.toString() ?? '',
      inventoryId: json['inventoryId']?.toString() ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      packageCount: json['amountOfPackage'] is int
          ? json['amountOfPackage'] as int
          : 0,
      packageLimit: json['packageLimit'] is int
          ? json['packageLimit'] as int
          : int.tryParse(json['packageLimit']?.toString() ?? '') ?? 0,
      createdDate: json['createdDate']?.toString() ??
          json['createdAt']?.toString() ??
          '',
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      active: json['active'] is bool ? json['active'] as bool : true,
      imageUrl: resolveMediaUrl(json['imageUrl'] as String?),
      productImages: productImages,
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      inventoryId: inventoryId,
      type: type,
      name: name,
      description: description,
      packageCount: packageCount,
      packageLimit: packageLimit,
      createdDate: createdDate,
      createdBy: createdBy,
      updatedBy: updatedBy,
      updatedAt: updatedAt,
      active: active,
      imageUrl: imageUrl,
      productImages: productImages,
    );
  }
}
