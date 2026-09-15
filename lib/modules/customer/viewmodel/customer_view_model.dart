import 'package:dio/dio.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import '../model/customer_models.dart';
import '../repository/customer_repository.dart';
import '../repository/customer_repository_impl.dart';

class CustomerViewModel extends BaseViewModel {
  final CustomerRepository _repository;

  CustomerAnalytics? _analytics;
  CustomerAnalytics? get analytics => _analytics;

  List<CustomerSearchResult> _searchResults = [];
  List<CustomerSearchResult> get searchResults => _searchResults;

  CustomerViewModel({CustomerRepository? repository})
      : _repository = repository ?? CustomerRepositoryImpl();

  Future<void> loadAnalytics() async {
    setLoading(true);
    resetError();
    try {
      final data = await _repository.getAnalytics(cancelToken: cancelToken);
      _analytics = CustomerAnalytics.fromJson(data);
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
      final data = await _repository.searchCustomers(
        query: query,
        cancelToken: cancelToken,
      );
      _searchResults = data.map((c) => CustomerSearchResult.fromJson(c)).toList();
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }
}
