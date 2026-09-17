import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/customer/domain/entities/customer.dart';
import 'package:posfrontend/features/customer/domain/repositories/customer_repository.dart';

class GetCustomersUseCase extends UseCase<Map<String, dynamic>, GetCustomersParams> {
  final CustomerRepository repository;

  GetCustomersUseCase(this.repository);

  @override
  Future<Map<String, dynamic>> call(GetCustomersParams params) {
    return repository.getCustomers(search: params.search, page: params.page);
  }
}

class GetCustomersParams {
  final String? search;
  final int page;

  GetCustomersParams({this.search, this.page = 1});
}

class GetCustomerUseCase extends UseCase<Map<String, dynamic>, String> {
  final CustomerRepository repository;

  GetCustomerUseCase(this.repository);

  @override
  Future<Map<String, dynamic>> call(String id) {
    return repository.getCustomer(id);
  }
}

class GetCustomerAnalyticsUseCase extends UseCase<CustomerAnalyticsEntity, NoParams> {
  final CustomerRepository repository;

  GetCustomerAnalyticsUseCase(this.repository);

  @override
  Future<CustomerAnalyticsEntity> call(NoParams params) {
    return repository.getAnalytics();
  }
}

class SearchCustomersUseCase extends UseCase<List<CustomerSearchResultEntity>, SearchCustomersParams> {
  final CustomerRepository repository;

  SearchCustomersUseCase(this.repository);

  @override
  Future<List<CustomerSearchResultEntity>> call(SearchCustomersParams params) {
    return repository.searchCustomers(query: params.query);
  }
}

class SearchCustomersParams {
  final String? query;

  SearchCustomersParams({this.query});
}
