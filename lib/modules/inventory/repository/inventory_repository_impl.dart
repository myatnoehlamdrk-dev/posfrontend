import 'package:dio/dio.dart';
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

      final List<dynamic> data = _asList(resp.data);
      if (data.isNotEmpty) {
        return Inventory.fromJson(data.first as Map<String, dynamic>);
      }

      // No inventory row yet: create-or-get it (backend uses firstOrCreate
      // keyed by shop_id + type), so we always resolve a valid inventory id.
      final created = await dio.post(
        '/api/inventories',
        data: {'type': type},
      );
      final createdData = _asList(created.data);
      final Map<String, dynamic> createdJson = createdData.isNotEmpty
          ? createdData.first as Map<String, dynamic>
          : created.data as Map<String, dynamic>;
      return Inventory.fromJson(createdJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      return inner is List ? inner : [];
    }
    return [];
  }
}
