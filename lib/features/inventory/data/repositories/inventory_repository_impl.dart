import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:posfrontend/features/inventory/domain/entities/inventory.dart';
import 'package:posfrontend/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource _dataSource;

  InventoryRepositoryImpl({InventoryRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? InventoryRemoteDataSource();

  @override
  List<InventoryOptionEntity> getOptions() => const [
        InventoryOptionEntity(
          key: 'self',
          title: 'Self Inventory',
          description: 'Manage products and stocks only for your own shop.',
        ),
        InventoryOptionEntity(
          key: 'public',
          title: 'Public Inventory',
          description: 'View and manage products and stocks shared publicly.',
        ),
      ];

  @override
  Future<InventoryEntity> getInventoryByType(String type) async {
    try {
      final data = await _dataSource.getInventories(type: type);
      if (data.isNotEmpty) {
        return data.first.toEntity();
      }

      final created = await _dataSource.createInventory(type: type);
      if (created.isNotEmpty) {
        return created.first.toEntity();
      }

      throw const ApiException(message: 'Failed to get inventory');
    } on ApiException {
      rethrow;
    }
  }
}
