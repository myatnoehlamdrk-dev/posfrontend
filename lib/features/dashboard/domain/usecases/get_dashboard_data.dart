import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardDataUseCase extends UseCase<DashboardEntity, DashboardParams> {
  final DashboardRepository _repository;

  GetDashboardDataUseCase(this._repository);

  @override
  Future<DashboardEntity> call(DashboardParams params) {
    return _repository.getDashboardData(days: params.days);
  }
}

class DashboardParams {
  final int days;

  const DashboardParams({this.days = 30});
}
