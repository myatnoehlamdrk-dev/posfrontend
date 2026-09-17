import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardViewModel extends BaseViewModel {
  final DashboardRepository _repository;

  DashboardViewModel({required DashboardRepository repository})
      : _repository = repository;

  DashboardEntity? _data;
  DashboardEntity? get data => _data;

  int _days = 365;
  bool _isLoadingTrend = false;
  bool get isLoadingTrend => _isLoadingTrend;

  Future<void> load({int? days}) async {
    if (days != null) _days = days;
    final result = await runAsync(
      (token) => _repository.getDashboardData(days: _days),
      errorPrefix: 'Failed to load dashboard',
    );
    if (result != null) _data = result;
  }

  Future<void> loadTrend({required int days}) async {
    _isLoadingTrend = true;
    notifyListeners();
    try {
      final result = await _repository.getDashboardData(days: days);
      if (_data != null) {
        _data = DashboardEntity(
          metrics: _data!.metrics,
          trendSeries: result.trendSeries,
          mostBought: _data!.mostBought,
          leastBought: _data!.leastBought,
        );
      }
    } catch (_) {
      // Trend load failure is non-critical; keep existing data
    }
    _isLoadingTrend = false;
    notifyListeners();
  }
}
