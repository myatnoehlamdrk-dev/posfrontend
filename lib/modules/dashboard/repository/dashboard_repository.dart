import 'package:posfrontend/modules/dashboard/model/dashboard_models.dart';

abstract class DashboardRepository {
  Future<DashboardData> getDashboardData();
}
