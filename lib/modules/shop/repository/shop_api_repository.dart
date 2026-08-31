import 'package:posfrontend/modules/shop/model/shop.dart';

abstract class ShopApiRepository {
  Future<Shop> createShop(Shop shop);
  Future<List<Shop>> getShops();
  Future<Shop> getShopById(String id);
}
