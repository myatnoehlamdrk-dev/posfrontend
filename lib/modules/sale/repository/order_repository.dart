import 'package:posfrontend/modules/sale/model/sale_models.dart';

abstract class OrderRepository {
  Future<void> createOrder({
    required String userName,
    required String voucherNo,
    required String orderId,
    String? customerName,
    String? customerPhone,
    String? payMethod,
    required List<SaleItem> items,
    required double grandTotal,
    int? discount,
    String? notes,
    String status,
  });

  Future<void> updateOrderStatus({required String orderId, required String status});

  Future<void> deleteOrder(String orderId);
}
