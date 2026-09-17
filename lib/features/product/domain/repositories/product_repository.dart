import 'package:dio/dio.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getProducts({String? packageId, CancelToken? cancelToken});
  Future<ProductEntity?> getProductById(String productId);
  Future<void> deleteProduct(String productId);
}
