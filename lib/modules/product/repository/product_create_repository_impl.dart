import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/package/repository/package_repository_impl.dart';
import 'package:posfrontend/modules/product/model/product_create_models.dart';
import 'product_create_repository.dart';

class ProductCreateRepositoryImpl implements ProductCreateRepository {
  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      return inner is List ? inner : [];
    }
    return [];
  }

  @override
  Future<List<SupplierOption>> getSuppliers() async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get('/api/suppliers');
      final data = _asList(resp.data);
      return data
          .map((e) => SupplierOption(
                id: (e['id'] ?? '').toString(),
                name: e['name'] ?? '',
              ))
          .toList();
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<PackageOption>> getPackages(String categoryId) async {
    try {
      final packages = await PackageRepositoryImpl().getPackages(categoryId);
      return packages
          .map((p) => PackageOption(id: p.id, name: p.name))
          .toList();
    } on ApiException {
      return [];
    }
  }

  @override
  Future<void> createProduct(ProductCreateRequest request) async {
    try {
      final dio = ApiClient.create();
      await dio.post('/api/products', data: request.toJson());
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> updateProduct(String id, ProductCreateRequest request) async {
    try {
      final dio = ApiClient.create();
      await dio.put('/api/products/$id', data: request.toJson());
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<ProductSearchResult>> searchProducts(String query) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get('/api/products/search', queryParameters: {'q': query});
      final data = _asList(resp.data);
      return data
          .map((e) => ProductSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<PendingPurchaseItem>> getPendingPurchaseItems() async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get('/api/purchase-items', queryParameters: {'status': 'pending'});
      final data = _asList(resp.data);
      return data
          .map((e) => PendingPurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  @override
  Future<void> completePurchaseItem(String id) async {
    try {
      final dio = ApiClient.create();
      await dio.put('/api/purchase-items/$id', data: {'status': 'completed'});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
