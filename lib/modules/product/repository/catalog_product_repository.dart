import 'package:dio/dio.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';

abstract class CatalogProductRepository {
  Future<List<CatalogProduct>> getProducts({String? packageId, CancelToken? cancelToken});
}
