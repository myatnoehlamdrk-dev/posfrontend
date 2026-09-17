import 'package:dio/dio.dart';
import 'package:posfrontend/features/product/domain/entities/product_detail.dart';

abstract class ProductDetailRepository {
  Future<ProductDetailEntity> getDetail(String productId, {CancelToken? cancelToken});
}
