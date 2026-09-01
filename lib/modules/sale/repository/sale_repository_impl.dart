import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/sale/model/sale_models.dart';
import 'package:posfrontend/modules/sale/repository/sale_repository.dart';

class SaleRepositoryImpl implements SaleRepository {
  @override
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
      'payMethod': payMethod,
      'items': itemsData,
      'grandTotal': grandTotal,
      if (discount != null) 'discount': discount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final resp = await dio.post('/api/sales', data: payload);
    if (resp.statusCode != 201) {
      throw ApiException(
        statusCode: resp.statusCode,
        message: 'Failed to save sale',
      );
    }
  }
}
