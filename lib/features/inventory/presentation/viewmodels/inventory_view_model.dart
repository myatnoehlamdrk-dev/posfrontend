import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/inventory/domain/entities/inventory.dart';
import 'package:posfrontend/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryViewModel extends BaseViewModel {
  final InventoryRepository _repository;

  InventoryViewModel({required InventoryRepository repository})
      : _repository = repository;

  List<InventoryOptionEntity> get options => _repository.getOptions();
}
