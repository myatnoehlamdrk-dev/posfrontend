import 'package:posfrontend/modules/product/model/product_detail_models.dart';

abstract class ProductDetailRepository {
  Future<ProductDetail> getDetail(String productId);
}
