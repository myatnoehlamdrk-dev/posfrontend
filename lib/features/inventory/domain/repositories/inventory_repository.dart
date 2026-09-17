import 'package:posfrontend/features/inventory/domain/entities/inventory.dart';

abstract class InventoryRepository {
  List<InventoryOptionEntity> getOptions();
  Future<InventoryEntity> getInventoryByType(String type);
}
