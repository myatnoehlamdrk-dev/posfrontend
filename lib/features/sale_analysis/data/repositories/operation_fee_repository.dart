import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:posfrontend/core/extensions/api_response_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';

class OperationFeeRepository {
  final Dio _dio;

  OperationFeeRepository([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  Future<Map<String, dynamic>> list() async {
    final response = await _dio.get('/operation-fees');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/operation-fees', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/operation-fees/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  /// Downloads the operation-fee report for one month as CSV bytes.
  Future<Uint8List> downloadReport({
    required int year,
    required int month,
  }) async {
    final response = await _dio.get(
      '/operation-fees/report',
      queryParameters: {'year': year, 'month': month},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  /// Real product-impact figures for one month under [allocationMethod].
  ///
  /// Passing [productId] previews that product; otherwise the backend picks
  /// the month's highest-revenue product.
  Future<Map<String, dynamic>> productImpact({
    required int year,
    required int month,
    required String allocationMethod,
    int? productId,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/operation-fees/product-impact',
      queryParameters: {
        'year': year,
        'month': month,
        'allocationMethod': allocationMethod,
        'productId': ?productId,
      },
      cancelToken: cancelToken,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Products in the shop matching [query], for the preview picker.
  Future<List<Map<String, dynamic>>> searchProducts(
    String query, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/products/search',
      queryParameters: {'q': query},
      cancelToken: cancelToken,
    );
    return parseApiList(
      response.data,
    ).whereType<Map<String, dynamic>>().toList();
  }

  Future<void> delete(int id) async {
    await _dio.delete('/operation-fees/$id');
  }

  Future<String> getSettings() async {
    final response = await _dio.get('/operation-fees/settings');
    return (response.data as Map<String, dynamic>)['allocationMethod']
            as String? ??
        'revenue';
  }

  Future<void> updateSettings(String method) async {
    await _dio.put(
      '/operation-fees/settings',
      data: {'allocationMethod': method},
    );
  }
}
