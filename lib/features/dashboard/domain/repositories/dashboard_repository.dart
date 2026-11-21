import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';

abstract class DashboardRepository {
  Future<DashboardEntity> getDashboardData({int days = 30});

  Future<({List<int> years, List<MonthlySalesEntity> months})> getMonthlySales({
    required int year,
  });

  /// Daily order counts and revenue for the last [days] days.
  Future<List<SalesChartPointEntity>> getSalesChart({required int days});

  /// Units sold across every category in the last [days] days — the sum the
  /// dashboard shows as Items Sold, available for any window so two windows
  /// can be differenced into a trend.
  Future<int> getItemsSold({required int days});

  /// Rows for one page of a "View all" table.
  Future<TablePage> getTable({
    required String endpoint,
    required int page,
    int perPage = 15,
    Map<String, dynamic> query = const {},
  });

  /// Top payment method by transaction count, plus the full distribution so
  /// the dashboard can render every method as a segment instead of one.
  Future<({String method, int count, double percent, List<({String method, int count, double percent})> distribution})>
      getTopPaymentMethod({
    int days = 30,
  });
}
