import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/shop/model/shop.dart';
import 'package:posfrontend/modules/shop/repository/shop_api_repository.dart';

class ShopApiRepositoryImpl implements ShopApiRepository {
  final Dio _dio;

  ShopApiRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.create();

  @override
  Future<Shop> createShop(Shop shop, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.post('/api/shops', data: shop.toApiJson(), cancelToken: cancelToken);
      return Shop.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<Shop>> getShops({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get('/api/shops', cancelToken: cancelToken);
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
  Future<Shop> getShopById(String id, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get('/api/shops/$id', cancelToken: cancelToken);
      return Shop.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
