import 'package:dio/dio.dart';
import 'package:posfrontend/core/auth/session_store.dart';
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

    // Network first. The cache used to be read first and returned whenever it
    // held any row, which meant a phone with a warm local table never asked the
    // server again: a new purchase never appeared and a status change never
    // stuck. The cache is now the fallback for a failed request, not the answer
    // to a good one.
    try {
      final response = await _remoteDataSource.getPurchaseItems(
        page: page,
        status: status,
        cancelToken: cancelToken,
      );
      await _cachePage(shopId: shopId, response: response);
      return response;
    } catch (e) {
      final cached = await _cachedPage(shopId: shopId, status: status, page: page);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Keeps the last successful page for offline use.
  ///
  /// Best-effort: a local write failure (full disk, a database file that
  /// predates the purchase_items table) must never turn a successful network
  /// read into a full-screen error with a Retry button that fails identically.
  Future<void> _cachePage({
    required String? shopId,
    required Map<String, dynamic> response,
  }) async {
    if (shopId == null || shopId.isEmpty) return;
    try {
      final data = response['data'];
      if (data is! List) return;
      final items = data
          .whereType<Map<String, dynamic>>()
          .map(PurchaseOrderApiModel.fromJson)
          .toList();
      await _localDataSource.cachePurchaseItems(shopId: shopId, items: items);
    } catch (_) {
      // Ignore cache write errors and keep the network data.
    }
  }

  /// Rebuilds one page of the list from the local table in the same shape the
  /// API answers with, so the view model parses both paths the same way.
  ///
  /// The rows go back as JSON maps, not as models: the caller feeds `data`
  /// straight into [PurchaseOrder.fromJson]-style parsing, and a list of model
  /// objects fails that type check and looks like an empty page.
  Future<Map<String, dynamic>?> _cachedPage({
    required String? shopId,
    required String? status,
    required int page,
  }) async {
    if (shopId == null || shopId.isEmpty) return null;
    try {
      final cached = await _localDataSource.getCachedPurchaseItems(
        shopId: shopId,
        status: status,
        page: page,
        // Same page size as the API, so a full local page means the same
        // thing it means remotely and the paging maths do not drift.
        perPage: _pageSize,
      );
      if (cached.isEmpty) return null;
      return {
        'data': cached.map((item) => item.toJson()).toList(),
        'meta': {
          'current_page': page,
          'last_page': 1,
          'total': cached.length,
        },
      };
    } catch (_) {
      // A broken cache is not an error worth showing; let the network failure
      // speak for itself.
      return null;
    }
  }

  /// Mirrors the backend's `per_page` for the purchase list.
  static const int _pageSize = 10;

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