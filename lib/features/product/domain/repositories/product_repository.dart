import 'package:dio/dio.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';

abstract class ProductRepository {
  /// [preferNetwork] asks for a fresh answer first (the package detail and
  /// assign screens read state they are about to edit); the cache is only
  /// served when the network fails, so going offline still shows data.
  Future<Map<String, dynamic>> getProducts({
    String? packageId,
    String? categoryId,
    String? search,
    String? sort,
    String? order,
    int page = 1,
    int perPage = 10,
    bool preferNetwork = false,
    CancelToken? cancelToken,
  });
  Future<ProductEntity?> getProductById(String productId);

  /// Moves [productId] into package [packageId] (`null` removes it) and keeps
  /// the local cache row in step, so the package detail list and the assign
  /// picker — both cache-first — never keep showing the old membership.
  Future<void> setProductPackage(
    String productId,
    int? packageId, {
    CancelToken? cancelToken,
  });

  Future<void> deleteProduct(String productId);
}
