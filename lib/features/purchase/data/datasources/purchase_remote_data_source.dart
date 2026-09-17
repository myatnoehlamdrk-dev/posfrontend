import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/purchase/data/models/purchase_api_model.dart';

class PurchaseRemoteDataSource {
  final Dio _dio;

  PurchaseRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<Map<String, dynamic>> getPurchaseItems({int page = 1, String? status, CancelToken? cancelToken}) async {
    final params = <String, dynamic>{'page': page};
    if (status != null) params['status'] = status;
    final response = await _dio.get('/api/purchase-items', queryParameters: params, cancelToken: cancelToken);
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {'data': payload};
  }

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
    final data = <String, dynamic>{
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'date': date,
    };
    if (supplierId != null && supplierId.isNotEmpty) {
      data['supplierId'] = int.tryParse(supplierId);
    }
    if (notes != null && notes.isNotEmpty) {
      data['notes'] = notes;
    }
    if (size != null && size.isNotEmpty) {
      data['size'] = size;
    }
    if (color != null && color.isNotEmpty) {
      data['color'] = color;
    }
    if (brand != null && brand.isNotEmpty) {
      data['brand'] = brand;
    }
    if (sku != null && sku.isNotEmpty) {
      data['sku'] = sku;
    }
    final response = await _dio.post('/api/purchase-items', data: data, cancelToken: cancelToken);
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {'data': payload};
  }

  Future<Map<String, dynamic>> updatePurchaseItemStatus({
    required String id,
    required String status,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.put('/api/purchase-items/$id', data: {'status': status}, cancelToken: cancelToken);
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {'data': payload};
  }

  Future<void> deletePurchaseItem(String id, {CancelToken? cancelToken}) async {
    await _dio.delete('/api/purchase-items/$id', cancelToken: cancelToken);
  }

  Future<List<SupplierApiModel>> getSuppliers({CancelToken? cancelToken}) async {
    final response = await _dio.get('/api/suppliers', cancelToken: cancelToken);
    final payload = response.data;
    List<dynamic> itemsList;
    if (payload is Map<String, dynamic>) {
      itemsList = payload['data'] as List<dynamic>? ?? [];
    } else if (payload is List) {
      itemsList = payload;
    } else {
      itemsList = [];
    }
    return itemsList
        .whereType<Map<String, dynamic>>()
        .map((e) => SupplierApiModel.fromJson(e))
        .toList();
  }

  Future<SupplierApiModel> createSupplier({
    required String name,
    String? contact,
    String? address,
    CancelToken? cancelToken,
  }) async {
    final data = <String, dynamic>{
      'name': name,
    };
    if (contact != null && contact.isNotEmpty) {
      data['contact'] = contact;
    }
    if (address != null && address.isNotEmpty) {
      data['address'] = address;
    }
    final response = await _dio.post('/api/suppliers', data: data, cancelToken: cancelToken);
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return SupplierApiModel.fromJson(payload);
    }
    return SupplierApiModel(id: '', name: name, phone: contact ?? '', address: address ?? '');
  }
}
