import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';

abstract class DashboardRepository {
  Future<DashboardEntity> getDashboardData({int days = 30});
}
