import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/shop/data/models/shop_api_model.dart';

class ShopApiDataSource {
  final Dio _dio;

  ShopApiDataSource({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<ShopApiModel> createShop(ShopApiModel shop, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.post(
        '/api/shops',
        data: shop.toApiJson(),
        cancelToken: cancelToken,
      );
      return ShopApiModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ShopApiModel>> getShops({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get('/api/shops', cancelToken: cancelToken);
      final payload = response.data;
      final list = payload is Map<String, dynamic>
          ? (payload['data'] as List? ?? const [])
          : (payload as List? ?? const []);
      return list
          .map((e) => ShopApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ShopApiModel> getShopById(String id, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get('/api/shops/$id', cancelToken: cancelToken);
      return ShopApiModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
