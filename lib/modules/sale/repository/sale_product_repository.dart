import 'package:posfrontend/modules/product/model/catalog_product.dart';

abstract class SaleProductRepository {
  Future<List<CatalogProduct>> getProducts();
}
