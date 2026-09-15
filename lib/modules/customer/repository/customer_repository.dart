import 'package:dio/dio.dart';

abstract class CustomerRepository {
  Future<Map<String, dynamic>> getCustomers({
    String? search,
    int page = 1,
    CancelToken? cancelToken,
  });
  Future<Map<String, dynamic>> getCustomer(String id, {CancelToken? cancelToken});
  Future<Map<String, dynamic>> getAnalytics({CancelToken? cancelToken});
  Future<List<Map<String, dynamic>>> searchCustomers({
    String? query,
    CancelToken? cancelToken,
  });
}
