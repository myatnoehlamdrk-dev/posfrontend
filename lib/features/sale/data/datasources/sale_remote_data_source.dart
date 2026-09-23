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

  Future<String> createOrder({
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
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        return data['id']?.toString() ?? '';
      }
      return '';
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

  Future<String> addOrderItems({
    required String orderId,
    required List<SaleItemEntity> items,
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

    try {
      final resp = await _dio.post('/api/orders/$orderId/items', data: {
        'items': itemsData,
      });
      if (resp.statusCode != 200) {
        throw ApiException(statusCode: resp.statusCode, message: 'Failed to add items to order');
      }
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        return data['id']?.toString() ?? '';
      }
      return '';
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

  Future<Map<String, dynamic>> getSales({int page = 1, int perPage = 10}) async {
    try {
      final response = await _dio.get('/api/sales', queryParameters: {'page': page, 'per_page': perPage});
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is List) return {'data': data, 'meta': {'current_page': page, 'last_page': 1, 'total': data.length}};
      return {'data': [], 'meta': {'current_page': 1, 'last_page': 1, 'total': 0}};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getOrders({int page = 1, int perPage = 10}) async {
    try {
      final response = await _dio.get('/api/orders', queryParameters: {'page': page, 'per_page': perPage});
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is List) return {'data': data, 'meta': {'current_page': page, 'last_page': 1, 'total': data.length}};
      return {'data': [], 'meta': {'current_page': 1, 'last_page': 1, 'total': 0}};
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
