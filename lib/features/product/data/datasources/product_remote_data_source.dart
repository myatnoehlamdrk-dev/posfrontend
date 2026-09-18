import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/product/data/models/product_api_model.dart';
import 'package:posfrontend/features/product/data/models/product_detail_api_model.dart';
import 'package:posfrontend/features/product/data/models/category_api_model.dart';

class ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSource([Dio? dio]) : _dio = dio ?? ApiClient.create();

  Future<List<ProductApiModel>> getProducts({String? packageId, CancelToken? cancelToken}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (packageId != null && packageId.isNotEmpty) {
        queryParams['packageId'] = packageId;
      }
      final response = await _dio.get('/api/products', queryParameters: queryParams, cancelToken: cancelToken);
      final data = response.data;
      final List<dynamic> items = data is Map ? (data['data'] ?? data['products'] ?? []) : (data as List? ?? []);
      return items.map((json) => ProductApiModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProductDetailApiModel> getProductDetail(String productId, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get('/api/products/$productId', cancelToken: cancelToken);
      final data = response.data;
      final json = data is Map ? (data['data'] ?? data) : data;
      return ProductDetailApiModel.fromJson(json as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _dio.delete('/api/products/$productId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ProductApiModel>> searchProducts(String query) async {
    try {
      final response = await _dio.get('/api/products', queryParameters: {'search': query});
      final data = response.data;
      final List<dynamic> items = data is Map ? (data['data'] ?? []) : (data as List? ?? []);
      return items.map((json) => ProductApiModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final response = await _dio.get('/api/suppliers');
      final data = response.data;
      final List<dynamic> items = data is Map ? (data['data'] ?? []) : (data as List? ?? []);
      return items.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPackages() async {
    try {
      final response = await _dio.get('/api/packages');
      final data = response.data;
      final List<dynamic> items = data is Map ? (data['data'] ?? []) : (data as List? ?? []);
      return items.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/products', data: data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/api/products/$productId', data: data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPendingPurchaseItems() async {
    try {
      final response = await _dio.get('/api/purchase-items/pending');
      final data = response.data;
      final List<dynamic> items = data is Map ? (data['data'] ?? []) : (data as List? ?? []);
      return items.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> completePurchaseItem(String itemId) async {
    try {
      await _dio.put('/api/purchase-items/$itemId/complete');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<CategoryApiModel>> getCategories() async {
    try {
      final response = await _dio.get('/api/categories');
      final data = response.data;
      final List<dynamic> items = data is Map ? (data['data'] ?? []) : (data as List? ?? []);
      return items.map((json) => CategoryApiModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> createCategory({required String name, String? description, String? inventoryId, String? type}) async {
    try {
      await _dio.post('/api/categories', data: {
        'name': name,
        if (description != null) 'description': description,
        if (inventoryId != null) 'inventoryId': inventoryId,
        if (type != null) 'type': type,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateCategory(String id, {String? name, String? description, bool? active}) async {
    try {
      await _dio.patch('/api/categories/$id', data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (active != null) 'active': active,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
