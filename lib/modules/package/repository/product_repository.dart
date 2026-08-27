import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/package/model/product_models.dart';

abstract class ProductRepository {
  List<Product> getProducts(Package package);
}
