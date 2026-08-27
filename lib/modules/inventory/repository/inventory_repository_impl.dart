import 'package:posfrontend/modules/inventory/model/inventory_models.dart';
import 'package:posfrontend/modules/inventory/repository/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  @override
  List<InventoryOption> getOptions() => const [
        InventoryOption(
          'self',
          'Self Inventory',
          'Manage products and stocks only for your own shop.',
        ),
        InventoryOption(
          'public',
          'Public Inventory',
          'View and manage products and stocks shared publicly.',
        ),
      ];
}
