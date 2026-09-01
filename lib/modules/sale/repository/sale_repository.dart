import 'package:posfrontend/modules/sale/model/sale_models.dart';

abstract class SaleRepository {
  Future<void> createSale({
    required String userName,
    required String voucherNo,
    required String orderId,
    String? customerName,
    String? payMethod,
    required List<SaleItem> items,
    required double grandTotal,
    int? discount,
    String? notes,
  });
}
