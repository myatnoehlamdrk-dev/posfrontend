import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';

abstract class SaleItemRepository {
  Future<Map<String, dynamic>> getSales({int page = 1});
  Future<Map<String, dynamic>> getOrders({int page = 1});
  Future<Map<String, dynamic>> getSaleById(String id);
}

class SaleItemRepositoryImpl implements SaleItemRepository {
  late final Dio _dio;

  SaleItemRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.create();

  @override
  Future<Map<String, dynamic>> getSales({int page = 1}) async {
    final response = await _dio.get('/api/sales', queryParameters: {'page': page});
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {'data': payload};
  }

  @override
  Future<Map<String, dynamic>> getOrders({int page = 1}) async {
    final response = await _dio.get('/api/orders', queryParameters: {'page': page});
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {'data': payload};
  }

  @override
  Future<Map<String, dynamic>> getSaleById(String id) async {
    final response = await _dio.get('/api/sales/$id');
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {'data': payload};
  }
}
