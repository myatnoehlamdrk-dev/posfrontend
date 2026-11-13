import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';

class OperationFeeRepository {
  final Dio _dio;

  OperationFeeRepository([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  Future<Map<String, dynamic>> list({int? year, int? month}) async {
    final response = await _dio.get(
      '/operation-fees',
      queryParameters: {
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data, {int? year, int? month}) async {
    final response = await _dio.post(
      '/operation-fees',
      data: {
        ...data,
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/operation-fees/$id', data: data);
    return response.data as Map<String, dynamic>;
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
