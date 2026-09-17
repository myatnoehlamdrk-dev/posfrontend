import 'package:posfrontend/features/customer/domain/entities/customer.dart';

abstract class CustomerRepository {
  Future<Map<String, dynamic>> getCustomers({String? search, int page = 1});
  Future<Map<String, dynamic>> getCustomer(String id);
  Future<CustomerAnalyticsEntity> getAnalytics();
  Future<List<CustomerSearchResultEntity>> searchCustomers({String? query});
}
