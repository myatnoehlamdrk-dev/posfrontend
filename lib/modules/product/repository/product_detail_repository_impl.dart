import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/product/model/product_detail_models.dart';
import 'package:posfrontend/modules/product/repository/product_detail_repository.dart';

class ProductDetailRepositoryImpl implements ProductDetailRepository {
  @override
  Future<ProductDetail> getDetail(String productId) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get('/api/products/$productId');
      final data = resp.data;
      final json =
          data is Map && data['data'] is Map ? data['data'] as Map<String, dynamic> : data as Map<String, dynamic>;
      return ProductDetail.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
