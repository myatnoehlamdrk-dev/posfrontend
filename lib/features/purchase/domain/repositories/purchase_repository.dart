import 'package:dio/dio.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';

abstract class PurchaseItemRepository {
  Future<Map<String, dynamic>> getPurchaseItems({int page = 1, String? status, CancelToken? cancelToken});
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
  });
  Future<Map<String, dynamic>> updatePurchaseItemStatus({
    required String id,
    required String status,
    CancelToken? cancelToken,
  });
  Future<void> deletePurchaseItem(String id, {CancelToken? cancelToken});
  Future<List<SupplierEntity>> getSuppliers({CancelToken? cancelToken});
  Future<SupplierEntity> createSupplier({
    required String name,
    String? contact,
    String? address,
    CancelToken? cancelToken,
  });
}
