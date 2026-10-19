import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/purchase/data/models/purchase_api_model.dart';

class PurchaseRemoteDataSource {
  final Dio _dio;

  PurchaseRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  Future<Map<String, dynamic>> getPurchaseItems({
    int page = 1,
    String? status,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (status != null) params['status'] = status;
    final response = await _dio.get(
      '/purchase-items',
      queryParameters: params,
      cancelToken: cancelToken,
      // This is the slowest endpoint in the API: the first query after TiDB
      // Serverless goes idle can take 12s+ of cold start on top of normal
      // latency. The shared 20s receive timeout turns that into a screen-
      // wide failure, so this call gets more headroom; a genuine hang still
      // ends in the timeout rather than waiting forever.
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
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
    final response = await _dio.post(
      '/purchase-items',
      data: data,
      cancelToken: cancelToken,
    );
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
    final response = await _dio.put(
      '/purchase-items/$id',
      data: {'status': status},
      cancelToken: cancelToken,
    );
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {'data': payload};
  }

  Future<void> deletePurchaseItem(String id, {CancelToken? cancelToken}) async {
    await _dio.delete('/purchase-items/$id', cancelToken: cancelToken);
  }

  Future<List<SupplierApiModel>> getSuppliers({
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/suppliers',
      cancelToken: cancelToken,
      // Loaded alongside purchase-items on the same screen; same remote-DB
      // cold-start exposure, so the same headroom.
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
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
    final data = <String, dynamic>{'name': name};
    if (contact != null && contact.isNotEmpty) {
      data['contact'] = contact;
    }
    if (address != null && address.isNotEmpty) {
      data['address'] = address;
    }
    final response = await _dio.post(
      '/suppliers',
      data: data,
      cancelToken: cancelToken,
    );
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return SupplierApiModel.fromJson(payload);
    }
    return SupplierApiModel(
      id: '',
      name: name,
      phone: contact ?? '',
      address: address ?? '',
    );
  }
}
