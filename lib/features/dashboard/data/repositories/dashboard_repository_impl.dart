import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
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
          );
        })
        .where((e) => e.month >= 1 && e.month <= 12)
        .toList();
    return (years: years, months: months);
  }
}