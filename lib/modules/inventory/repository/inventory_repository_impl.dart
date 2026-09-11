import 'package:dio/dio.dart';
import 'package:posfrontend/core/extensions/api_response_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
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

  @override
  Future<Inventory> getInventoryByType(String type) async {
    try {
      final dio = ApiClient.create();

      final resp = await dio.get(
        '/api/inventories',
        queryParameters: {'type': type},
      );

      final data = parseTypedList(resp.data, Inventory.fromJson);
      if (data.isNotEmpty) {
        return data.first;
      }

      // No inventory row yet: create-or-get it (backend uses firstOrCreate
      // keyed by shop_id + type), so we always resolve a valid inventory id.
      final created = await dio.post(
        '/api/inventories',
        data: {'type': type},
      );
      final createdData = parseTypedList(created.data, Inventory.fromJson);
      if (createdData.isNotEmpty) {
        return createdData.first;
      }
      final Map<String, dynamic> createdJson = created.data as Map<String, dynamic>;
      return Inventory.fromJson(createdJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
