import 'package:posfrontend/features/sale/domain/entities/sale.dart';

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
  });
}

abstract class OrderRepository {
  Future<void> createOrder({
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
  Future<void> deleteOrder(String orderId);
}

abstract class SaleHistoryRepository {
  Future<List<SaleOrderEntity>> getSales({int page = 1});
  Future<List<SaleOrderEntity>> getOrders({int page = 1});
  Future<SaleOrderEntity> getSaleById(String id);
  Future<SaleOrderEntity> getOrderById(String id);
  Future<void> deleteSale(String id);
  Future<SaleOrderEntity> deleteSaleItem(String saleId, String itemId);
}
