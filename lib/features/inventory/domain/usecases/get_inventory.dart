import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/inventory/domain/entities/inventory.dart';
import 'package:posfrontend/features/inventory/domain/repositories/inventory_repository.dart';

class GetInventoryOptionsUseCase
    extends UseCase<List<InventoryOptionEntity>, NoParams> {
  final InventoryRepository _repository;
  GetInventoryOptionsUseCase(this._repository);

  @override
  Future<List<InventoryOptionEntity>> call(NoParams params) async {
    return _repository.getOptions();
  }
}

class GetInventoryUseCase
    extends UseCase<InventoryEntity, GetInventoryParams> {
  final InventoryRepository _repository;
  GetInventoryUseCase(this._repository);

  @override
  Future<InventoryEntity> call(GetInventoryParams params) {
    return _repository.getInventoryByType(params.type);
  }
}

class GetInventoryParams {
  final String type;
  const GetInventoryParams({required this.type});
}
