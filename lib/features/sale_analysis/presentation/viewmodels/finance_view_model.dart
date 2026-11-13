import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:posfrontend/features/sale_analysis/presentation/money_flow/money_flow_data.dart';

/// View model for the Finance / Money Flow screen.
///
/// Fetches real monthly revenue from the backend and exposes it as
/// [MoneyFlowMonth] objects so the UI can render real inflow figures.
/// Outflow, operation fee and net still use demo values until those
/// data sources are wired up.
class FinanceViewModel extends BaseViewModel {
  final DashboardRepository _repository;

  FinanceViewModel({required DashboardRepository repository})
      : _repository = repository;

  List<MoneyFlowMonth> _months = [];
  List<MoneyFlowMonth> get months => _months;

  // Real COGS per month (from variant cost_price * quantity).
  final Map<int, int> _cogsByMonth = {};
  int cogsFor(int month) => _cogsByMonth[month] ?? 0;

  // Real units sold per month.
  final Map<int, int> _unitsByMonth = {};
  int unitsFor(int month) => _unitsByMonth[month] ?? 0;

  // Real transaction count per month.
  final Map<int, int> _txnsByMonth = {};
  int txnsFor(int month) => _txnsByMonth[month] ?? 0;

  // Real purchase cost per month (outflow).
  final Map<int, int> _purchasesByMonth = {};
  int purchasesFor(int month) => _purchasesByMonth[month] ?? 0;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  List<int> _years = [];
  List<int> get years => _years;

  MoneyFlowMonth? monthFor(DateTime date) {
    for (final m in _months) {
      if (m.month.year == date.year && m.month.month == date.month) {
        return m;
      }
    }
    return null;
  }

  MoneyFlowMonth? previousMonthOf(DateTime date) {
    final prev = DateTime(date.year, date.month - 1);
    return monthFor(prev);
  }

  List<MoneyFlowMonth> yearMonths(int year) {
    final result = <MoneyFlowMonth>[];
    for (var m = 1; m <= 12; m++) {
      final found = _months.where(
        (x) => x.month.year == year && x.month.month == m,
      );
      if (found.isNotEmpty) {
        result.add(found.first);
      } else {
        result.add(MoneyFlowMonth(
          month: DateTime(year, m),
          inflow: 0,
          outflow: 0,
          operationFee: 0,
        ));
      }
    }
    return result;
  }

  Future<void> load({int? year}) async {
    if (year != null) _selectedYear = year;
    await runAsync((token) async {
      final result = await _repository.getMonthlySales(year: _selectedYear);
      _years = result.years;
      if (_years.isEmpty) _years = [_selectedYear];
      // Build MoneyFlowMonth list from real revenue and outflow.
      // Operation fee stays demo (user-configured rules).
      final demoByMonth = <int, MoneyFlowMonth>{
        for (final m in moneyFlowMonths) m.month.month: m,
      };
      _months = result.months.map((ms) {
        final demo = demoByMonth[ms.month];
        _cogsByMonth[ms.month] = ms.cogs;
        _unitsByMonth[ms.month] = ms.units;
        _txnsByMonth[ms.month] = ms.transactions;
        _purchasesByMonth[ms.month] = ms.purchases;
        return MoneyFlowMonth(
          month: DateTime(_selectedYear, ms.month),
          inflow: ms.total.toDouble(),
          outflow: ms.purchases.toDouble(),
          operationFee: demo?.operationFee ?? 0,
        );
      }).toList();
    }, errorPrefix: 'Failed to load finance data');
  }
}
