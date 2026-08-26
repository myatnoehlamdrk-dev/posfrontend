import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/shop/model/shop.dart';
import 'package:posfrontend/modules/shop/repository/shop_api_repository.dart';

class ShopApiRepositoryImpl implements ShopApiRepository {
  final Dio _dio;

  ShopApiRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.create();

  @override
  Future<Shop> createShop(Shop shop) async {
    try {
      // Shop controller: POST {BASE_URL}/api/shops
      final response = await _dio.post('/api/shops', data: shop.toApiJson());
      return Shop.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
