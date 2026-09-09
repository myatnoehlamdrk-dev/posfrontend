import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/modules/dashboard/model/dashboard_models.dart';
import 'package:posfrontend/modules/dashboard/repository/dashboard_repository.dart';

class DashboardViewModel extends BaseViewModel {
  final DashboardRepository _repository;

  DashboardViewModel({required DashboardRepository repository})
      : _repository = repository;

  DashboardData? _data;
  DashboardData? get data => _data;

  int _days = 365;

  Future<void> load({int? days}) async {
    if (days != null) _days = days;
    final result = await runAsync(
      () => _repository.getDashboardData(days: _days),
      errorPrefix: 'Failed to load dashboard',
    );
    if (result != null) _data = result;
  }
}
