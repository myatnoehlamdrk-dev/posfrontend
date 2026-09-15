import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final Dio _dio = ApiClient.instance;

  @override
  Future<Map<String, dynamic>> getCustomers({
    String? search,
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _dio.get(
      '/api/customers',
      queryParameters: params,
      cancelToken: cancelToken,
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getCustomer(String id, {CancelToken? cancelToken}) async {
    final response = await _dio.get('/api/customers/$id', cancelToken: cancelToken);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getAnalytics({CancelToken? cancelToken}) async {
    final response = await _dio.get('/api/customers/analytics', cancelToken: cancelToken);
    return response.data;
  }

  @override
  Future<List<Map<String, dynamic>>> searchCustomers({
    String? query,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/api/customers/search',
      queryParameters: {'query': query ?? ''},
      cancelToken: cancelToken,
    );
    return List<Map<String, dynamic>>.from(response.data);
  }
}
