import 'package:dio/dio.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/sale_items/model/sale_item_models.dart';
import 'package:posfrontend/modules/sale_items/model/sale_list_response.dart';
import 'package:posfrontend/modules/sale_items/repository/sale_item_repository.dart';

class SaleItemRepositoryImpl implements SaleItemRepository {
  late final Dio _dio;

  SaleItemRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.create();

  @override
  Future<PaginatedSalesResponse> getSales({int page = 1}) async {
    try {
      final response = await _dio.get('/api/sales', queryParameters: {'page': page});
      final payload = response.data;
      if (payload is List) {
        final items = payload
            .whereType<Map<String, dynamic>>()
            .map((e) => SaleOrder.fromJson(e))
            .toList();
        return PaginatedResponse(data: items, lastPage: 1, currentPage: 1, total: items.length);
      }
      if (payload is Map<String, dynamic>) {
        return PaginatedResponse.fromJson(payload, SaleOrder.fromJson);
      }
      return const PaginatedResponse(data: [], lastPage: 1, currentPage: 1, total: 0);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<PaginatedOrdersResponse> getOrders({int page = 1}) async {
    try {
      final response = await _dio.get('/api/orders', queryParameters: {'page': page});
      final payload = response.data;
      if (payload is List) {
        final items = payload
            .whereType<Map<String, dynamic>>()
            .map((e) => SaleOrder.fromOrderJson(e))
            .toList();
        return PaginatedResponse(data: items, lastPage: 1, currentPage: 1, total: items.length);
      }
      if (payload is Map<String, dynamic>) {
        return PaginatedResponse.fromJson(payload, SaleOrder.fromOrderJson);
      }
      return const PaginatedResponse(data: [], lastPage: 1, currentPage: 1, total: 0);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SaleDetailResponse> getSaleById(String id) async {
    try {
      final response = await _dio.get('/api/sales/$id');
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return SaleDetailResponse.fromJson(payload);
      }
      throw ApiException(message: 'Invalid response format');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SaleOrder> getOrderById(String id) async {
    try {
      final response = await _dio.get('/api/orders/$id');
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return SaleOrder.fromOrderJson(payload);
      }
      throw ApiException(message: 'Invalid response format');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteSale(String id) async {
    try {
      await _dio.delete('/api/sales/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteOrder(String id) async {
    try {
      await _dio.delete('/api/orders/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SaleOrder> deleteSaleItem(String saleId, String itemId) async {
    try {
      final response = await _dio.delete('/api/sales/$saleId/items/$itemId');
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return SaleOrder.fromJson(payload);
      }
      throw ApiException(message: 'Invalid response format');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
