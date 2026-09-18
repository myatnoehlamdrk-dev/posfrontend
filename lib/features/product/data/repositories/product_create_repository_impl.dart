import 'package:dio/dio.dart';
import 'package:posfrontend/core/extensions/api_response_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/product/data/models/product_create_models.dart';
import 'package:posfrontend/features/product/domain/repositories/product_create_repository.dart';
import 'package:posfrontend/features/package/domain/repositories/package_repository.dart';
import 'package:posfrontend/features/package/data/repositories/package_repository_impl.dart';

class ProductCreateRepositoryImpl implements ProductCreateRepository {
  final PackageRepository _packageRepository;

  ProductCreateRepositoryImpl({PackageRepository? packageRepository})
      : _packageRepository = packageRepository ?? PackageRepositoryImpl();

  @override
  Future<List<SupplierOption>> getSuppliers({CancelToken? cancelToken}) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get('/api/suppliers', cancelToken: cancelToken);
      return parseTypedList(resp.data, (e) => SupplierOption(
            id: (e['id'] ?? '').toString(),
            name: e['name'] ?? '',
          ));
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<PackageOption>> getPackages(String categoryId, {CancelToken? cancelToken}) async {
    try {
      final packages = await _packageRepository.getPackages(categoryId, cancelToken: cancelToken);
      return packages
          .map((p) => PackageOption(id: p.id, name: p.name))
          .toList();
    } on ApiException {
      return [];
    }
  }

  @override
  Future<void> createProduct(ProductCreateRequest request, {CancelToken? cancelToken}) async {
    try {
      final dio = ApiClient.create();
      await dio.post('/api/products', data: request.toJson(), cancelToken: cancelToken);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> updateProduct(String id, ProductCreateRequest request, {CancelToken? cancelToken}) async {
    try {
      final dio = ApiClient.create();
      await dio.patch('/api/products/$id', data: request.toJson(), cancelToken: cancelToken);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<ProductSearchResult>> searchProducts(String query, {CancelToken? cancelToken}) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get('/api/products/search', queryParameters: {'q': query}, cancelToken: cancelToken);
      return parseTypedList(resp.data, ProductSearchResult.fromJson);
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<PendingPurchaseItem>> getPendingPurchaseItems({CancelToken? cancelToken}) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get('/api/purchase-items', queryParameters: {'status': 'pending'}, cancelToken: cancelToken);
      return parseTypedList(resp.data, PendingPurchaseItem.fromJson);
    } on DioException {
      return [];
    }
  }

  @override
  Future<void> completePurchaseItem(String id, {CancelToken? cancelToken}) async {
    try {
      final dio = ApiClient.create();
      await dio.put('/api/purchase-items/$id', data: {'status': 'completed'}, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
