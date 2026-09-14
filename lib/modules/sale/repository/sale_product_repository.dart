import 'package:dio/dio.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';

abstract class SaleProductRepository {
  Future<List<CatalogProduct>> getProducts({CancelToken? cancelToken});
}
