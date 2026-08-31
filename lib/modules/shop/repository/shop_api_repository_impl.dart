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

  @override
  Future<List<Shop>> getShops() async {
    try {
      // Shop controller: GET {BASE_URL}/api/shops (public, paginated).
      final response = await _dio.get('/api/shops');
      final payload = response.data;
      final list = payload is Map<String, dynamic>
          ? (payload['data'] as List? ?? const [])
          : (payload as List? ?? const []);
      return list
          .map((e) => Shop.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Shop> getShopById(String id) async {
    try {
      final response = await _dio.get('/api/shops/$id');
      return Shop.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
