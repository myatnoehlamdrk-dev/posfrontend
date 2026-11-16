import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:posfrontend/features/sale_analysis/presentation/money_flow/money_flow_data.dart';

/// View model for the Finance / Money Flow screen.
///
/// Fetches real monthly figures from the backend — revenue, purchases (outflow),
/// cost of goods, units and the operation-fee cost computed from the shop's
/// fee rules — and exposes them as [MoneyFlowMonth] objects.
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
      // Build MoneyFlowMonth list from real revenue, outflow and the
      // operation-fee cost computed from the shop-wide rules.
      _months = result.months.map((ms) {
        _cogsByMonth[ms.month] = ms.cogs;
        _unitsByMonth[ms.month] = ms.units;
        _txnsByMonth[ms.month] = ms.transactions;
        _purchasesByMonth[ms.month] = ms.purchases;
        return MoneyFlowMonth(
          month: DateTime(_selectedYear, ms.month),
          inflow: ms.total.toDouble(),
          outflow: ms.purchases.toDouble(),
          operationFee: ms.operationFee,
        );
      }).toList();
    }, errorPrefix: 'Failed to load finance data');
  }
}
