import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/modules/dashboard/model/dashboard_models.dart';
import 'package:posfrontend/modules/dashboard/repository/dashboard_repository.dart';

class DashboardViewModel extends BaseViewModel {
  final DashboardRepository _repository;

  DashboardViewModel({required DashboardRepository repository})
      : _repository = repository;

  DashboardData? _data;
  DashboardData? get data => _data;

  Future<void> load() async {
    setLoading(true);
    try {
      _data = await _repository.getDashboardData();
    } catch (e) {
      setError('Failed to load dashboard');
    } finally {
      setLoading(false);
    }
  }
}
