import 'package:equatable/equatable.dart';

class InventoryOptionEntity extends Equatable {
  final String key;
  final String title;
  final String description;

  const InventoryOptionEntity({
    required this.key,
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [key];
}

class InventoryEntity extends Equatable {
  final String id;
  final String shopId;
  final String type;
  final int amountCategory;

  const InventoryEntity({
    required this.id,
    required this.shopId,
    required this.type,
    this.amountCategory = 0,
  });

  @override
  List<Object?> get props => [id];
}
