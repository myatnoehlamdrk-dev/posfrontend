import 'package:posfrontend/core/extensions/map_json_extensions.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';
import 'package:posfrontend/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:posfrontend/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:posfrontend/features/dashboard/data/models/dashboard_api_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl({DashboardRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? DashboardRemoteDataSource();

  @override
  Future<DashboardEntity> getDashboardData({int days = 30}) async {
    final json = await _remoteDataSource.getDashboardData(days: days);
    return DashboardApiModel.fromJson(json).toEntity();
  }

  @override
  Future<({List<int> years, List<MonthlySalesEntity> months})> getMonthlySales({
    required int year,
  }) async {
    final json = await _remoteDataSource.getMonthlySales(year: year);
    final years = (json['years'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    final months = (json['months'] as List<dynamic>? ?? [])
        .map((e) {
          final item = e as Map<String, dynamic>;
          return MonthlySalesEntity(
            month: (item['month'] as num?)?.toInt() ?? 0,
            total: (item['total'] as num?)?.toInt() ?? 0,
            cogs: (item['cogs'] as num?)?.toInt() ?? 0,
            units: (item['units'] as num?)?.toInt() ?? 0,
            transactions: (item['transactions'] as num?)?.toInt() ?? 0,
            purchases: (item['purchases'] as num?)?.toInt() ?? 0,
            operationFee: (item['operation_fee'] as num?)?.toDouble() ?? 0,
          );
        })
        .where((e) => e.month >= 1 && e.month <= 12)
        .toList();
    return (years: years, months: months);
  }

  @override
  Future<List<SalesChartPointEntity>> getSalesChart({required int days}) async {
    final rows = await _remoteDataSource.getSalesChart(days: days);
    return rows.whereType<Map<String, dynamic>>().map((row) {
      // The column is `DATE(created_at)`, so it parses as a date-only
      // timestamp; an unparseable one becomes the epoch rather than throwing,
      // which drops the point out of both windows below instead of failing
      // the whole comparison.
      final date = DateTime.tryParse(row.str('date')) ?? DateTime(1970);
      return SalesChartPointEntity(
        date: date,
        orders: row.integer('count'),
        total: row.integer('total'),
      );
    }).toList();
  }

  @override
  Future<int> getItemsSold({required int days}) async {
    // The full dashboard payload carries `category_quantity`, and no lighter
    // endpoint exposes it — so this reads the same document the dashboard
    // does and takes only the one list off it.
    final json = await _remoteDataSource.getDashboardData(days: days);
    final rows = (json['category_quantity'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();

    var total = 0;
    for (final row in rows) {
      total += row.integer('total_quantity');
    }
    return total;
  }

  @override
  Future<TablePage> getTable({
    required String endpoint,
    required int page,
    int perPage = 15,
    Map<String, dynamic> query = const {},
  }) async {
    final json = await _remoteDataSource.getTable(
      endpoint: endpoint,
      page: page,
      perPage: perPage,
      query: query,
    );

    final rows = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DashboardTableRow.new)
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return TablePage(
      rows: rows,
      page: (meta['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? rows.length,
      perPage: (meta['per_page'] as num?)?.toInt() ?? perPage,
    );
  }

  @override
  Future<({String method, int count, double percent, List<({String method, int count, double percent})> distribution})>
      getTopPaymentMethod({
    int days = 30,
  }) async {
    try {
      final json = await _remoteDataSource.getTable(
        endpoint: '/dashboard/tables/sales',
        page: 1,
        perPage: 500, // Get enough to calculate distribution
        query: {'days': days},
      );

      final rows = (json['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();

      // Count payment methods
      final Map<String, int> counts = {};
      for (final row in rows) {
        final method = row['pay_method']?.toString() ?? 'Unknown';
        counts[method] = (counts[method] ?? 0) + 1;
      }

      if (counts.isEmpty) {
        return (
          method: 'N/A',
          count: 0,
          percent: 0.0,
          distribution: const <({String method, int count, double percent})>[],
        );
      }

      // Build the full distribution, sorted by count descending.
      final total = counts.values.fold<int>(0, (sum, c) => sum + c);
      final distribution = <({String method, int count, double percent})>[
        for (final entry in counts.entries)
          (
            method: entry.key,
            count: entry.value,
            percent: total > 0 ? (entry.value / total * 100) : 0.0,
          ),
      ]..sort((a, b) => b.count.compareTo(a.count));

      final topEntry = distribution.first;

      return (
        method: topEntry.method,
        count: topEntry.count,
        percent: topEntry.percent,
        distribution: distribution,
      );
    } catch (e) {
      // If API fails, return N/A
      return (
        method: 'N/A',
        count: 0,
        percent: 0.0,
        distribution: const <({String method, int count, double percent})>[],
      );
    }
  }
}
