import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';
import 'package:posfrontend/features/purchase/domain/repositories/purchase_repository.dart';

class GetPurchaseItemsUseCase {
  final PurchaseItemRepository _repository;

  GetPurchaseItemsUseCase(this._repository);

  Future<Map<String, dynamic>> call({int page = 1, String? status}) =>
      _repository.getPurchaseItems(page: page, status: status);
}

class CreatePurchaseItemUseCase {
  final PurchaseItemRepository _repository;

  CreatePurchaseItemUseCase(this._repository);

  Future<Map<String, dynamic>> call({
    required String productName,
    required int quantity,
    required int unitPrice,
    required String date,
    String? supplierId,
    String? notes,
    String? size,
    String? color,
    String? brand,
    String? sku,
  }) =>
      _repository.createPurchaseItem(
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        date: date,
        supplierId: supplierId,
        notes: notes,
        size: size,
        color: color,
        brand: brand,
        sku: sku,
      );
}

class UpdatePurchaseItemStatusUseCase {
  final PurchaseItemRepository _repository;

  UpdatePurchaseItemStatusUseCase(this._repository);

  Future<Map<String, dynamic>> call({required String id, required String status}) =>
      _repository.updatePurchaseItemStatus(id: id, status: status);
}

class DeletePurchaseItemUseCase {
  final PurchaseItemRepository _repository;

  DeletePurchaseItemUseCase(this._repository);

  Future<void> call(String id) => _repository.deletePurchaseItem(id);
}

class GetSuppliersUseCase {
  final PurchaseItemRepository _repository;

  GetSuppliersUseCase(this._repository);

  Future<List<SupplierEntity>> call() => _repository.getSuppliers();
}

class CreateSupplierUseCase {
  final PurchaseItemRepository _repository;

  CreateSupplierUseCase(this._repository);

  Future<SupplierEntity> call({
    required String name,
    String? contact,
    String? address,
  }) =>
      _repository.createSupplier(name: name, contact: contact, address: address);
}
