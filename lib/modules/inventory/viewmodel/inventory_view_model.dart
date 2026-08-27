import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/modules/inventory/model/inventory_models.dart';
import 'package:posfrontend/modules/inventory/repository/inventory_repository.dart';

class InventoryViewModel extends BaseViewModel {
  final InventoryRepository _repository;

  InventoryViewModel({required InventoryRepository repository})
      : _repository = repository;

  List<InventoryOption> get options => _repository.getOptions();
}
