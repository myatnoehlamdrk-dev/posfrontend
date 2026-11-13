import 'dart:typed_data';

import 'package:dio/dio.dart';
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

  Future<void> delete(int id) async {
    await _dio.delete('/operation-fees/$id');
  }

  Future<String> getSettings() async {
    final response = await _dio.get('/operation-fees/settings');
    return (response.data as Map<String, dynamic>)['allocationMethod'] as String? ?? 'revenue';
  }

  Future<void> updateSettings(String method) async {
    await _dio.put('/operation-fees/settings', data: {'allocationMethod': method});
  }
}
