import 'package:dio/dio.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/features/purchase/data/datasources/purchase_local_data_source.dart';
import 'package:posfrontend/features/purchase/data/datasources/purchase_remote_data_source.dart';
import 'package:posfrontend/features/purchase/data/models/purchase_api_model.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';
import 'package:posfrontend/features/purchase/domain/repositories/purchase_repository.dart';

class PurchaseRepositoryImpl implements PurchaseItemRepository {
  final PurchaseRemoteDataSource _remoteDataSource;
  final PurchaseLocalDataSource _localDataSource;
  final Future<String?> Function() _currentShopId;

  PurchaseRepositoryImpl({
    PurchaseRemoteDataSource? remoteDataSource,
    PurchaseLocalDataSource? localDataSource,
    Future<String?> Function()? currentShopId,
  })  : _remoteDataSource = remoteDataSource ?? PurchaseRemoteDataSource(),
        _localDataSource = localDataSource ?? PurchaseLocalDataSource(),
        _currentShopId = currentShopId ?? SessionStore.currentShopId;

  @override
  Future<Map<String, dynamic>> getPurchaseItems({
    int page = 1,
    String? status,
    CancelToken? cancelToken,
  }) async {
    final shopId = await _currentShopId();
    if (shopId != null && shopId.isNotEmpty) {
      try {
        final cachedItems = await _localDataSource.getCachedPurchaseItems(
          shopId: shopId,
          status: status,
          page: page,
        );
        if (cachedItems.isNotEmpty) {
          return {
            'data': cachedItems,
            'meta': {
              'current_page': page,
              'last_page': 1,
              'total': cachedItems.length,
            },
          };
        }
      } catch (_) {
        // Ignore cache errors and fall back to network
      }
    }

    final response = await _remoteDataSource.getPurchaseItems(
      page: page,
      status: status,
      cancelToken: cancelToken,
    );

    // Cache the response for offline use
    if (shopId != null && shopId.isNotEmpty) {
      final data = response['data'];
      if (data is List) {
        final items = data
            .map((json) => PurchaseOrderApiModel.fromJson(json as Map<String, dynamic>))
            .toList();
        await _localDataSource.cachePurchaseItems(shopId: shopId, items: items);
      }
    }

    return response;
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
    return _remoteDataSource.createPurchaseItem(
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
    return _remoteDataSource.updatePurchaseItemStatus(id: id, status: status);
  }

  @override
  Future<void> deletePurchaseItem(String id, {CancelToken? cancelToken}) async {
    await _remoteDataSource.deletePurchaseItem(id);
  }

  @override
  Future<List<SupplierEntity>> getSuppliers({CancelToken? cancelToken}) async {
    final models = await _remoteDataSource.getSuppliers();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<SupplierEntity> createSupplier({
    required String name,
    String? contact,
    String? address,
    CancelToken? cancelToken,
  }) async {
    final model = await _remoteDataSource.createSupplier(
      name: name,
      contact: contact,
      address: address,
    );
    return model.toEntity();
  }
}