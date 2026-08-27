import 'package:posfrontend/modules/product/model/catalog_product.dart';

abstract class CatalogProductRepository {
  List<CatalogProduct> getProducts();
}
