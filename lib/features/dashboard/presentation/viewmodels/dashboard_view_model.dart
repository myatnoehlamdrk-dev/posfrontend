import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardViewModel extends BaseViewModel {
  final DashboardRepository _repository;

  DashboardViewModel({required DashboardRepository repository})
      : _repository = repository;

  DashboardEntity? _data;
  DashboardEntity? get data => _data;

  List<int> _years = [];
  List<int> get years => _years;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  List<MonthlySalesEntity> _monthlySales = [];
  List<MonthlySalesEntity> get monthlySales => _monthlySales;

  bool _isLoadingMonthly = false;
  bool get isLoadingMonthly => _isLoadingMonthly;

  String? _monthlyError;
  String? get monthlyError => _monthlyError;

  Future<void> load({int? days}) async {
    final result = await runAsync(
      (token) => _repository.getDashboardData(days: days ?? 365),
      errorPrefix: 'Failed to load dashboard',
    );
    if (result != null) _data = result;
    await loadMonthlySales(year: _selectedYear);
  }

  Future<void> loadMonthlySales({required int year}) async {
    _selectedYear = year;
    _isLoadingMonthly = true;
    _monthlyError = null;
    notifyListeners();
    try {
      final result = await _repository.getMonthlySales(year: year);
      if (result.years.isNotEmpty) _years = result.years;
      _monthlySales = result.months;
    } catch (e) {
      _monthlyError = e.toString();
    }
    _isLoadingMonthly = false;
    notifyListeners();
  }
}