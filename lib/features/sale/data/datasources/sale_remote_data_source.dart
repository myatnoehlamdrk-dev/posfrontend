import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/sale/data/models/sale_order_api_model.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';

class SaleRemoteDataSource {
  final Dio _dio;

  SaleRemoteDataSource([Dio? dio]) : _dio = dio ?? ApiClient.create();

  Future<void> createSale({
    required String userName,
    required String voucherNo,
    required String orderId,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? payMethod,
    required List<SaleItemEntity> items,
    required double grandTotal,
    int? discount,
    String? notes,
  }) async {
    final itemsData = items.map((item) => {
      'productId': int.tryParse(item.productId),
      'productName': item.productName,
      'quantity': item.quantity,
      'unitPrice': item.unitPrice,
      'subtotal': item.subtotal,
      if (item.size != null) 'size': item.size,
      if (item.color?.isNotEmpty == true) 'color': item.color,
      if (item.notes?.isNotEmpty == true) 'notes': item.notes,
    }).toList();

    final payload = {
      'userName': userName,
      'voucherNo': voucherNo,
      'orderId': orderId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerLocation': customerLocation,
      'payMethod': payMethod,
      'items': itemsData,
      'grandTotal': grandTotal,
      if (discount != null) 'discount': discount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      final resp = await _dio.post('/api/sales', data: payload);
      if (resp.statusCode != 201) {
        throw ApiException(statusCode: resp.statusCode, message: 'Failed to save sale');
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> createOrder({
    required String userName,
    required String voucherNo,
    required String orderId,
    String? customerName,
    String? customerPhone,
    String? payMethod,
    required List<SaleItemEntity> items,
    required double grandTotal,
    int? discount,
    String? notes,
    String status = 'draft',
  }) async {
    final itemsData = items.map((item) => {
      'productId': int.tryParse(item.productId),
      'productName': item.productName,
      'quantity': item.quantity,
      'unitPrice': item.unitPrice,
      'subtotal': item.subtotal,
      if (item.size != null) 'size': item.size,
      if (item.color?.isNotEmpty == true) 'color': item.color,
      if (item.notes?.isNotEmpty == true) 'notes': item.notes,
    }).toList();

    final payload = {
      'userName': userName,
      'voucherNo': voucherNo,
      'orderId': orderId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'payMethod': payMethod,
      'items': itemsData,
      'grandTotal': grandTotal,
      if (discount != null) 'discount': discount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'status': status,
    };

    try {
      final resp = await _dio.post('/api/orders', data: payload);
      if (resp.statusCode != 201) {
        throw ApiException(statusCode: resp.statusCode, message: 'Failed to save order');
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateOrderStatus({required String orderId, required String status}) async {
    try {
      await _dio.put('/api/orders/$orderId', data: {'status': status});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _dio.delete('/api/orders/$orderId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<SaleOrderApiModel>> getSales({int page = 1}) async {
    try {
      final response = await _dio.get('/api/sales', queryParameters: {'page': page});
      final payload = response.data;
      if (payload is List) {
        return payload.whereType<Map<String, dynamic>>().map((e) => SaleOrderApiModel.fromJson(e)).toList();
      }
      if (payload is Map<String, dynamic>) {
        final data = payload['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().map((e) => SaleOrderApiModel.fromJson(e)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<SaleOrderApiModel>> getOrders({int page = 1}) async {
    try {
      final response = await _dio.get('/api/orders', queryParameters: {'page': page});
      final payload = response.data;
      if (payload is List) {
        return payload.whereType<Map<String, dynamic>>().map((e) => SaleOrderApiModel.fromOrderJson(e)).toList();
      }
      if (payload is Map<String, dynamic>) {
        final data = payload['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().map((e) => SaleOrderApiModel.fromOrderJson(e)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SaleOrderApiModel> getSaleById(String id) async {
    try {
      final response = await _dio.get('/api/sales/$id');
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return SaleOrderApiModel.fromJson(payload);
      }
      throw ApiException(message: 'Invalid response format');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteSale(String id) async {
    try {
      await _dio.delete('/api/sales/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SaleOrderApiModel> deleteSaleItem(String saleId, String itemId) async {
    try {
      final response = await _dio.delete('/api/sales/$saleId/items/$itemId');
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return SaleOrderApiModel.fromJson(payload);
      }
      throw ApiException(message: 'Invalid response format');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
