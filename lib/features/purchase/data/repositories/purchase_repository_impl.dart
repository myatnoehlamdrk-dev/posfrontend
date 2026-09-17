import 'package:dio/dio.dart';
import 'package:posfrontend/features/purchase/data/datasources/purchase_remote_data_source.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';
import 'package:posfrontend/features/purchase/domain/repositories/purchase_repository.dart';

class PurchaseRepositoryImpl implements PurchaseItemRepository {
  final PurchaseRemoteDataSource _dataSource;

  PurchaseRepositoryImpl({PurchaseRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? PurchaseRemoteDataSource();

  @override
  Future<Map<String, dynamic>> getPurchaseItems({int page = 1, String? status, CancelToken? cancelToken}) async {
    return _dataSource.getPurchaseItems(page: page, status: status);
  }

  @override
  Future<Map<String, dynamic>> createPurchaseItem({
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
    CancelToken? cancelToken,
  }) async {
    return _dataSource.createPurchaseItem(
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

  @override
  Future<Map<String, dynamic>> updatePurchaseItemStatus({
    required String id,
    required String status,
    CancelToken? cancelToken,
  }) async {
    return _dataSource.updatePurchaseItemStatus(id: id, status: status);
  }

  @override
  Future<void> deletePurchaseItem(String id, {CancelToken? cancelToken}) async {
    await _dataSource.deletePurchaseItem(id);
  }

  @override
  Future<List<SupplierEntity>> getSuppliers({CancelToken? cancelToken}) async {
    final models = await _dataSource.getSuppliers();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<SupplierEntity> createSupplier({
    required String name,
    String? contact,
    String? address,
    CancelToken? cancelToken,
  }) async {
    final model = await _dataSource.createSupplier(
      name: name,
      contact: contact,
      address: address,
    );
    return model.toEntity();
  }
}
