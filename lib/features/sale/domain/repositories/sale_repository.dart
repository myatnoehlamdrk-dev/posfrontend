import 'package:dio/dio.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';

abstract class SaleProductRepository {
  Future<Map<String, dynamic>> getProducts({int page = 1, int perPage = 10, CancelToken? cancelToken});
}

abstract class SaleRepository {
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
    CancelToken? cancelToken,
  });
}

abstract class OrderRepository {
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
  });

  Future<void> updateOrderStatus({required String orderId, required String status});
  Future<String> addOrderItems({
    required String orderId,
    required List<SaleItemEntity> items,
  });
  Future<void> deleteOrder(String orderId);
}

abstract class SaleHistoryRepository {
  Future<Map<String, dynamic>> getSales({int page = 1, int perPage = 10});
  Future<Map<String, dynamic>> getOrders({int page = 1, int perPage = 10});
  Future<SaleOrderEntity> getSaleById(String id);
  Future<SaleOrderEntity> getOrderById(String id);
  Future<void> deleteSale(String id);
  Future<SaleOrderEntity> deleteSaleItem(String saleId, String itemId);
}
