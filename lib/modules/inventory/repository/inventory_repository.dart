import 'package:posfrontend/modules/inventory/model/inventory_models.dart';

abstract class InventoryRepository {
  List<InventoryOption> getOptions();
  Future<Inventory> getInventoryByType(String type);
}
