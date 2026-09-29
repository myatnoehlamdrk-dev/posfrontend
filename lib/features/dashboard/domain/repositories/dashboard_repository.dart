import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';

abstract class DashboardRepository {
  Future<DashboardEntity> getDashboardData({int days = 30});

  Future<({List<int> years, List<MonthlySalesEntity> months})> getMonthlySales({
    required int year,
  });

  /// Rows for one page of a "View all" table.
  Future<TablePage> getTable({
    required String endpoint,
    required int page,
    int perPage = 15,
    Map<String, dynamic> query = const {},
  });
}