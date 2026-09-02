import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/purchase_items/model/purchase_models.dart';

abstract class PurchaseItemRepository {
  Future<Map<String, dynamic>> getPurchaseItems({int page = 1, String? status});
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
  });
  Future<Map<String, dynamic>> updatePurchaseItemStatus({
    required String id,
    required String status,
  });
  Future<void> deletePurchaseItem(String id);
  Future<List<Supplier>> getSuppliers();
  Future<Supplier> createSupplier({
    required String name,
    String? contact,
    String? address,
  });
}

class PurchaseItemRepositoryImpl implements PurchaseItemRepository {
  late final Dio _dio;

  PurchaseItemRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.create();

  @override
  Future<Map<String, dynamic>> getPurchaseItems({int page = 1, String? status}) async {
    final params = <String, dynamic>{'page': page};
    if (status != null) params['status'] = status;
    final response = await _dio.get('/api/purchase-items', queryParameters: params);
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {'data': payload};
  }

  @override
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
    final response = await _dio.post('/api/purchase-items', data: data);
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {'data': payload};
  }

  @override
  Future<Map<String, dynamic>> updatePurchaseItemStatus({
    required String id,
    required String status,
  }) async {
    final response = await _dio.put('/api/purchase-items/$id', data: {'status': status});
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {'data': payload};
  }

  @override
  Future<void> deletePurchaseItem(String id) async {
    await _dio.delete('/api/purchase-items/$id');
  }

  @override
  Future<List<Supplier>> getSuppliers() async {
    final response = await _dio.get('/api/suppliers');
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
        .map((e) => Supplier.fromJson(e))
        .toList();
  }

  @override
  Future<Supplier> createSupplier({
    required String name,
    String? contact,
    String? address,
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
    final response = await _dio.post('/api/suppliers', data: data);
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return Supplier.fromJson(payload);
    }
    return Supplier(id: '', name: name, phone: contact ?? '', address: address ?? '');
  }
}
