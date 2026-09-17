import 'package:dio/dio.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/customer/domain/entities/customer.dart';
import 'package:posfrontend/features/customer/domain/repositories/customer_repository.dart';
import 'package:posfrontend/features/customer/data/repositories/customer_repository_impl.dart';

class CustomerViewModel extends BaseViewModel {
  final CustomerRepository _repository;

  CustomerAnalyticsEntity? _analytics;
  CustomerAnalyticsEntity? get analytics => _analytics;

  List<CustomerSearchResultEntity> _searchResults = [];
  List<CustomerSearchResultEntity> get searchResults => _searchResults;

  CustomerViewModel({CustomerRepository? repository})
      : _repository = repository ?? CustomerRepositoryImpl();

  Future<void> loadAnalytics() async {
    setLoading(true);
    resetError();
    try {
      final data = await _repository.getAnalytics();
      _analytics = data;
    } on DioException catch (e) {
      setError(e.message ?? 'Failed to load analytics');
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> searchCustomers(String query) async {
    try {
      final data = await _repository.searchCustomers(query: query);
      _searchResults = data;
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }
}
