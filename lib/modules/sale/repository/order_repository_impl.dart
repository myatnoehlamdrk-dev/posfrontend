import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/sale/model/sale_models.dart';
import 'package:posfrontend/modules/sale/repository/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  @override
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
    String status = 'draft',
  }) async {
    final dio = ApiClient.create();

    final itemsData = items
        .map((item) => {
              'productId': int.tryParse(item.productId),
              'productName': item.productName,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'subtotal': item.subtotal,
              if (item.size != null) 'size': item.size,
              if (item.color != null && item.color!.isNotEmpty)
                'color': item.color,
              if (item.notes != null && item.notes!.isNotEmpty)
                'notes': item.notes,
            })
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

    final resp = await dio.post('/api/orders', data: payload);
    if (resp.statusCode != 201) {
      throw ApiException(
        statusCode: resp.statusCode,
        message: 'Failed to save order',
      );
    }
  }
}
