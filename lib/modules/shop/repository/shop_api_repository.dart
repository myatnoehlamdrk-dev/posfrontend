import 'package:dio/dio.dart';
import 'package:posfrontend/modules/shop/model/shop.dart';

abstract class ShopApiRepository {
  Future<Shop> createShop(Shop shop, {CancelToken? cancelToken});
  Future<List<Shop>> getShops({CancelToken? cancelToken});
  Future<Shop> getShopById(String id, {CancelToken? cancelToken});
}
