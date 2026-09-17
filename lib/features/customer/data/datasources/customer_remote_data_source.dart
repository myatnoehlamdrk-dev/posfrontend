import 'package:dio/dio.dart';

abstract class CustomerRemoteDataSource {
  Future<Response> getCustomers({String? search, int page = 1, CancelToken? cancelToken});
  Future<Response> getCustomer(String id, {CancelToken? cancelToken});
  Future<Response> getAnalytics({CancelToken? cancelToken});
  Future<Response> searchCustomers({String? query, CancelToken? cancelToken});
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final Dio dio;

  CustomerRemoteDataSourceImpl(this.dio);

  @override
  Future<Response> getCustomers({String? search, int page = 1, CancelToken? cancelToken}) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    return dio.get('/api/customers', queryParameters: params, cancelToken: cancelToken);
  }

  @override
  Future<Response> getCustomer(String id, {CancelToken? cancelToken}) {
    return dio.get('/api/customers/$id', cancelToken: cancelToken);
  }

  @override
  Future<Response> getAnalytics({CancelToken? cancelToken}) {
    return dio.get('/api/customers/analytics', cancelToken: cancelToken);
  }

  @override
  Future<Response> searchCustomers({String? query, CancelToken? cancelToken}) {
    return dio.get('/api/customers/search', queryParameters: {'query': query ?? ''}, cancelToken: cancelToken);
  }
}
