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

  Future<Map<String, dynamic>> getMonthlySales({
    required int year,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/api/dashboard/monthly-sales',
      queryParameters: {'year': year},
      cancelToken: cancelToken,
    );
    return response.data as Map<String, dynamic>;
  }

  /// One of the paginated "View all" tables. [query] carries whatever the table
  /// filters on (low-stock flag, most/least direction, month).
  Future<Map<String, dynamic>> getTable({
    required String endpoint,
    required int page,
    required int perPage,
    Map<String, dynamic> query = const {},
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      endpoint,
      queryParameters: {'page': page, 'per_page': perPage, ...query},
      cancelToken: cancelToken,
    );
    return response.data as Map<String, dynamic>;
  }
}
