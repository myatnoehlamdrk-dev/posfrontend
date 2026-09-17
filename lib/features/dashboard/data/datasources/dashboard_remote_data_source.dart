import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';

class DashboardRemoteDataSource {
  final Dio _dio;

  DashboardRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<Map<String, dynamic>> getDashboardData({
    int days = 30,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/api/dashboard/all',
      queryParameters: {'days': days},
      cancelToken: cancelToken,
    );
    return response.data as Map<String, dynamic>;
  }
}
