import 'package:dio/dio.dart';
import 'package:posfrontend/features/product/data/models/product_create_models.dart';

abstract class ProductCreateRepository {
  Future<List<SupplierOption>> getSuppliers({CancelToken? cancelToken});
  Future<List<PackageOption>> getPackages(String categoryId, {CancelToken? cancelToken});
  Future<void> createProduct(ProductCreateRequest request, {CancelToken? cancelToken});
  Future<void> updateProduct(String id, ProductCreateRequest request, {CancelToken? cancelToken});
  Future<List<ProductSearchResult>> searchProducts(String query, {CancelToken? cancelToken});
  Future<List<PendingPurchaseItem>> getPendingPurchaseItems({CancelToken? cancelToken});
  Future<void> completePurchaseItem(String id, {CancelToken? cancelToken});
}
