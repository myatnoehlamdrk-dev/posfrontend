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
}
