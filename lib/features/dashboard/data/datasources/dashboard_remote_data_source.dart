import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';

class DashboardRemoteDataSource {
  final Dio _dio;

  DashboardRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  Future<Map<String, dynamic>> getDashboardData({
    int days = 30,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/dashboard/all',
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
      '/dashboard/monthly-sales',
      queryParameters: {'year': year},
      cancelToken: cancelToken,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Daily order counts and revenue for the last [days] days, oldest first.
  ///
  /// Returns the raw list because the endpoint is a bare JSON array, not an
  /// object; the shape is `[{date, count, total}, ...]` with days that had no
  /// sales absent rather than zeroed.
  Future<List<dynamic>> getSalesChart({
    required int days,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/dashboard/sales-chart',
      queryParameters: {'days': days},
      cancelToken: cancelToken,
    );
    return response.data as List<dynamic>;
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
