import 'package:posfrontend/modules/shop/model/shop.dart';

abstract class ShopLocalRepository {
  Future<void> saveShop(Shop shop);
  Future<Shop?> getShop();
  Future<void> clearShop();
}
