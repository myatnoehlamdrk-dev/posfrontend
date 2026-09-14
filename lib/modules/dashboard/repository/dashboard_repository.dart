import 'package:dio/dio.dart';
import 'package:posfrontend/modules/dashboard/model/dashboard_models.dart';

abstract class DashboardRepository {
  Future<DashboardData> getDashboardData({int days = 30, CancelToken? cancelToken});
}
