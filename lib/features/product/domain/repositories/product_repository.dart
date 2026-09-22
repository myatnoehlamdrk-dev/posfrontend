import 'package:dio/dio.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';

abstract class ProductRepository {
  Future<Map<String, dynamic>> getProducts({
    String? packageId,
    String? categoryId,
    String? search,
    String? sort,
    String? order,
    int page = 1,
    int perPage = 10,
    CancelToken? cancelToken,
  });
  Future<ProductEntity?> getProductById(String productId);
  Future<void> deleteProduct(String productId);
}
