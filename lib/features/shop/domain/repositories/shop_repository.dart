import 'package:dio/dio.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart';

abstract class ShopApiRepository {
  Future<ShopEntity> createShop(ShopEntity shop, {CancelToken? cancelToken});
  Future<List<ShopEntity>> getShops({CancelToken? cancelToken});
  Future<ShopEntity> getShopById(String id, {CancelToken? cancelToken});
}

abstract class ShopLocalRepository {
  Future<void> saveShop(ShopEntity shop);
  Future<ShopEntity?> getShop();
  Future<void> clearShop();
}
