import 'package:dio/dio.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart';

abstract class ShopApiRepository {
  Future<ShopEntity> createShop(ShopEntity shop, {CancelToken? cancelToken});
  Future<List<ShopEntity>> getShops({String? query, CancelToken? cancelToken});
  Future<ShopEntity> getShopById(String id, {CancelToken? cancelToken});
  Future<ShopEntity> updateShop(
    String id,
    ShopEntity shop, {
    CancelToken? cancelToken,
  });
}

abstract class ShopLocalRepository {
  Future<void> saveShop(ShopEntity shop);
  Future<ShopEntity?> getShop();
  Future<void> clearShop();
}
