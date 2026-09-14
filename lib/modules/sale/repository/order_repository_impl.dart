import 'package:dio/dio.dart';
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
    CancelToken? cancelToken,
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
              if (item.color?.isNotEmpty == true)
                'color': item.color,
              if (item.notes?.isNotEmpty == true)
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

    final resp = await dio.post('/api/orders', data: payload, cancelToken: cancelToken);
    if (resp.statusCode != 201) {
      throw ApiException(
        statusCode: resp.statusCode,
        message: 'Failed to save order',
      );
    }
  }

  @override
  Future<void> updateOrderStatus({required String orderId, required String status, CancelToken? cancelToken}) async {
    final dio = ApiClient.create();
    final resp = await dio.put('/api/orders/$orderId', data: {'status': status}, cancelToken: cancelToken);
    if (resp.statusCode != 200) {
      throw ApiException(
        statusCode: resp.statusCode,
        message: 'Failed to update order status',
      );
    }
  }

  @override
  Future<void> deleteOrder(String orderId, {CancelToken? cancelToken}) async {
    final dio = ApiClient.create();
    final resp = await dio.delete('/api/orders/$orderId', cancelToken: cancelToken);
    if (resp.statusCode != 200) {
      throw ApiException(
        statusCode: resp.statusCode,
        message: 'Failed to delete order',
      );
    }
  }
}
