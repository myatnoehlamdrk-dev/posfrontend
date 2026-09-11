import 'package:dio/dio.dart';
import 'package:posfrontend/core/extensions/api_response_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/package/repository/package_repository.dart';
import 'package:posfrontend/modules/package/repository/package_repository_impl.dart';
import 'package:posfrontend/modules/product/model/product_create_models.dart';
import 'product_create_repository.dart';

class ProductCreateRepositoryImpl implements ProductCreateRepository {
  final PackageRepository _packageRepository;

  ProductCreateRepositoryImpl({PackageRepository? packageRepository})
      : _packageRepository = packageRepository ?? PackageRepositoryImpl();

  @override
  Future<List<SupplierOption>> getSuppliers() async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get('/api/suppliers');
      return parseTypedList(resp.data, (e) => SupplierOption(
            id: (e['id'] ?? '').toString(),
            name: e['name'] ?? '',
          ));
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<PackageOption>> getPackages(String categoryId) async {
    try {
      final packages = await _packageRepository.getPackages(categoryId);
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
      return parseTypedList(resp.data, ProductSearchResult.fromJson);
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<PendingPurchaseItem>> getPendingPurchaseItems() async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get('/api/purchase-items', queryParameters: {'status': 'pending'});
      return parseTypedList(resp.data, PendingPurchaseItem.fromJson);
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
