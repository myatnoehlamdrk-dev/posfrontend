import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? inventoryId;
  final String? type;
  final int? packageCount;
  final int? packageLimit;
  final bool active;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.description,
    this.inventoryId,
    this.type,
    this.packageCount,
    this.packageLimit,
    this.active = true,
  });

  @override
  List<Object?> get props => [id, name];
}
