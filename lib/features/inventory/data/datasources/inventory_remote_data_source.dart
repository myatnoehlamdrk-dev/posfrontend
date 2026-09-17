import 'package:dio/dio.dart';
import 'package:posfrontend/core/extensions/api_response_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/inventory/data/models/inventory_api_model.dart';

class InventoryRemoteDataSource {
  final Dio _dio;
  InventoryRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<List<InventoryApiModel>> getInventories({
    String? type,
    CancelToken? cancelToken,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (type != null) queryParameters['type'] = type;
    final resp = await _dio.get(
      '/api/inventories',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      cancelToken: cancelToken,
    );
    return parseTypedList(resp.data, InventoryApiModel.fromJson);
  }

  Future<List<InventoryApiModel>> createInventory({
    required String type,
    CancelToken? cancelToken,
  }) async {
    final resp = await _dio.post(
      '/api/inventories',
      data: {'type': type},
      cancelToken: cancelToken,
    );
    return parseTypedList(resp.data, InventoryApiModel.fromJson);
  }
}
