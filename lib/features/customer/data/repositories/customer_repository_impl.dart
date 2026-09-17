import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/customer/domain/entities/customer.dart';
import 'package:posfrontend/features/customer/domain/repositories/customer_repository.dart';
import 'package:posfrontend/features/customer/data/models/customer_api_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final dio = ApiClient.instance;

  @override
  Future<Map<String, dynamic>> getCustomers({String? search, int page = 1}) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await dio.get('/api/customers', queryParameters: params);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getCustomer(String id) async {
    final response = await dio.get('/api/customers/$id');
    return response.data;
  }

  @override
  Future<CustomerAnalyticsEntity> getAnalytics() async {
    final response = await dio.get('/api/customers/analytics');
    return CustomerApiModel.analyticsFromJson(response.data);
  }

  @override
  Future<List<CustomerSearchResultEntity>> searchCustomers({String? query}) async {
    final response = await dio.get('/api/customers/search', queryParameters: {'query': query ?? ''});
    return CustomerApiModel.searchResultsFromJson(response.data);
  }
}
