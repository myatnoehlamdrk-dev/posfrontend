import 'package:posfrontend/features/inventory/domain/entities/inventory.dart';

class InventoryApiModel {
  final String id;
  final String shopId;
  final String type;
  final int amountCategory;

  const InventoryApiModel({
    required this.id,
    required this.shopId,
    required this.type,
    this.amountCategory = 0,
  });

  factory InventoryApiModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amountCategory'];
    return InventoryApiModel(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      type: json['type'] ?? '',
      amountCategory: rawAmount is int
          ? rawAmount
          : int.tryParse(rawAmount?.toString() ?? '') ?? 0,
    );
  }

  InventoryEntity toEntity() {
    return InventoryEntity(
      id: id,
      shopId: shopId,
      type: type,
      amountCategory: amountCategory,
    );
  }
}
