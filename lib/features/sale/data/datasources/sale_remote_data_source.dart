import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/offline/offline_writes_flag.dart';
import 'package:posfrontend/core/offline/outbox_queue.dart';
import 'package:posfrontend/features/sale/data/models/sale_order_api_model.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';

class SaleRemoteDataSource {
  final Dio _dio;

  SaleRemoteDataSource([Dio? dio]) : _dio = dio ?? ApiClient.create();

  Future<void> createSale({
    required String userName,
    required String voucherNo,
    required String orderId,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? payMethod,
    required List<SaleItemEntity> items,
    required double grandTotal,
    int? discount,
    String? notes,
  }) async {
    final itemsData = items
        .map(
          (item) => {
            'productId': int.tryParse(item.productId),
            'productName': item.productName,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'subtotal': item.subtotal,
            if (item.size != null) 'size': item.size,
            if (item.color?.isNotEmpty == true) 'color': item.color,
            if (item.notes?.isNotEmpty == true) 'notes': item.notes,
          },
        )
        .toList();

    final payload = {
      'userName': userName,
      'voucherNo': voucherNo,
      'orderId': orderId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerLocation': customerLocation,
      'payMethod': payMethod,
      'items': itemsData,
      'grandTotal': grandTotal,
      if (discount != null) 'discount': discount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      final resp = await _dio.post('/sales', data: payload);
      if (resp.statusCode != 201) {
        throw ApiException(
          statusCode: resp.statusCode,
          message: 'Failed to save sale',
        );
      }
    } on DioException catch (e) {
      // If the failure means the request never left the device, store the
      // sale in the outbox so the cashier's sale is not lost. This is the
      // only place we can see the exact payload before it gets wrapped into
      // an [ApiException], so it is the only place the enqueue decision can
      // be made without a second call to rebuild it.
      if (OfflineWrites.enabled && OutboxQueue.isConnectionLevel(e)) {
        final queued = await OutboxQueue.instance.enqueue(
          kind: 'sale',
          payload: payload,
        );
        if (queued) return;
      }
      throw ApiException.fromDio(e);
    }
  }

  /// Creates a draft order (reserving stock server-side) and returns its
  /// server id.
  ///
  /// With [allowLocalFallback] (the add-to-cart path) and the offline
  /// writes flag on, a connection-level failure returns a *local* id
  /// (`local:<uuid>`) instead of throwing: the cart card is saved on the
  /// device with its items, no draft exists on the server yet, and no
  /// stock is reserved. The draft is materialized when the sale completes
  /// — see [enqueueLocalCardSale] and `SaleViewModel.submitSale`.
  ///
  /// The materialize path passes `allowLocalFallback: false`: it needs a
  /// real server id, and a silent local id there would post a sale
  /// against an order that does not exist.
  Future<String> createOrder({
    required String userName,
    required String voucherNo,
    required String orderId,
    String? customerName,
    String? customerPhone,
    String? payMethod,
    required List<SaleItemEntity> items,
    required double grandTotal,
    int? discount,
    String? notes,
    String status = 'draft',
    bool allowLocalFallback = true,
  }) async {
    final itemsData = items
        .map(
          (item) => {
            'productId': int.tryParse(item.productId),
            'productName': item.productName,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'subtotal': item.subtotal,
            if (item.size != null) 'size': item.size,
            if (item.color?.isNotEmpty == true) 'color': item.color,
            if (item.notes?.isNotEmpty == true) 'notes': item.notes,
          },
        )
        .toList();

    final payload = {
      'userName': userName,
      'voucherNo': voucherNo,
      'orderId': orderId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'payMethod': payMethod,
      'items': itemsData,
      'grandTotal': grandTotal,
      if (discount != null) 'discount': discount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'status': status,
    };

    try {
      final resp = await _dio.post('/orders', data: payload);
      if (resp.statusCode != 201) {
        throw ApiException(
          statusCode: resp.statusCode,
          message: 'Failed to save order',
        );
      }
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        return data['id']?.toString() ?? '';
      }
      return '';
    } on DioException catch (e) {
      if (allowLocalFallback &&
          OfflineWrites.enabled &&
          OutboxQueue.isConnectionLevel(e)) {
        // Lazy draft: the card lives on this device only until the sale
        // completes. No outbox entry here — queueing the draft at
        // add-to-cart time would pin stock for a cart the cashier may
        // abandon, which the backend does when a draft order is created.
        return 'local:${OutboxQueue.newClientUuid()}';
      }
      throw ApiException.fromDio(e);
    }
  }

  /// Enqueues the compound "create draft, then convert it to a sale" pair
  /// for a cart that was *built* offline and has no server draft.
  ///
  /// Called by `SaleViewModel.submitSale` instead of the normal
  /// createSale path when the card's orderId is a local id. Returns false
  /// when nothing was stored (no session) — the caller must then surface
  /// an error rather than report a sale nothing recorded.
  Future<bool> enqueueLocalCardSale({
    required String userName,
    required String voucherNo,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? payMethod,
    required List<SaleItemEntity> items,
    required double grandTotal,
    int? discount,
    String? notes,
  }) async {
    final itemsData = items
        .map(
          (item) => {
            'productId': int.tryParse(item.productId),
            'productName': item.productName,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'subtotal': item.subtotal,
            if (item.size != null) 'size': item.size,
            if (item.color?.isNotEmpty == true) 'color': item.color,
            if (item.notes?.isNotEmpty == true) 'notes': item.notes,
          },
        )
        .toList();

    // The draft half is a normal draft order body; the backend overwrites
    // its client voucher/order ids anyway (OrderNumberService).
    final draft = {
      'userName': userName,
      'voucherNo': 'INV-${OutboxQueue.newClientUuid().substring(0, 8)}',
      'orderId': 'ORD-${OutboxQueue.newClientUuid().substring(0, 8)}',
      'items': itemsData,
      'grandTotal': grandTotal,
      'status': 'draft',
    };
    final sale = {
      'userName': userName,
      'voucherNo': voucherNo,
      // Placeholder replaced by the flush with the id the draft half
      // received — the local card id never reaches the wire.
      'orderId': '',
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerLocation': customerLocation,
      'payMethod': payMethod,
      'items': itemsData,
      'grandTotal': grandTotal,
      if (discount != null) 'discount': discount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    return OutboxQueue.instance.enqueue(
      kind: 'sale-from-draft',
      payload: {'draft': draft, 'sale': sale},
    );
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await _dio.put('/orders/$orderId', data: {'status': status});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> addOrderItems({
    required String orderId,
    required List<SaleItemEntity> items,
  }) async {
    final itemsData = items
        .map(
          (item) => {
            'productId': int.tryParse(item.productId),
            'productName': item.productName,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'subtotal': item.subtotal,
            if (item.size != null) 'size': item.size,
            if (item.color?.isNotEmpty == true) 'color': item.color,
            if (item.notes?.isNotEmpty == true) 'notes': item.notes,
          },
        )
        .toList();

    try {
      final resp = await _dio.post(
        '/orders/$orderId/items',
        data: {'items': itemsData},
      );
      if (resp.statusCode != 200) {
        throw ApiException(
          statusCode: resp.statusCode,
          message: 'Failed to add items to order',
        );
      }
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        return data['id']?.toString() ?? '';
      }
      return '';
    } on DioException catch (e) {
      // Appending to a server-backed draft while offline: queue the exact
      // request. FIFO guarantees it flushes before the sale entry that
      // later converts this draft, so stock is deducted for these items
      // before the sale claims them.
      if (OfflineWrites.enabled && OutboxQueue.isConnectionLevel(e)) {
        final queued = await OutboxQueue.instance.enqueue(
          kind: 'order-items',
          payload: {'orderId': orderId, 'items': itemsData},
        );
        if (queued) return '';
      }
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _dio.delete('/orders/$orderId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getSales({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/sales',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is List)
        return {
          'data': data,
          'meta': {'current_page': page, 'last_page': 1, 'total': data.length},
        };
      return {
        'data': [],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
      };
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/orders',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is List)
        return {
          'data': data,
          'meta': {'current_page': page, 'last_page': 1, 'total': data.length},
        };
      return {
        'data': [],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
      };
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SaleOrderApiModel> getSaleById(String id) async {
    try {
      final response = await _dio.get('/sales/$id');
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return SaleOrderApiModel.fromJson(payload);
      }
      throw ApiException(message: 'Invalid response format');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteSale(String id) async {
    try {
      await _dio.delete('/sales/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SaleOrderApiModel> deleteSaleItem(String saleId, String itemId) async {
    try {
      final response = await _dio.delete('/sales/$saleId/items/$itemId');
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return SaleOrderApiModel.fromJson(payload);
      }
      throw ApiException(message: 'Invalid response format');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
