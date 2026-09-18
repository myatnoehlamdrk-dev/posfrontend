import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/package/data/models/package_api_model.dart';

class PackageRemoteDataSource {
  final Dio _dio;

  PackageRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<List<PackageApiModel>> getPackages(String categoryId, {CancelToken? cancelToken}) async {
    try {
      final resp = await _dio.get(
        '/api/packages',
        queryParameters: {'categoryId': categoryId},
        cancelToken: cancelToken,
      );
      final data = resp.data;
      List<dynamic> itemsList;
      if (data is Map<String, dynamic>) {
        itemsList = data['data'] as List<dynamic>? ?? [];
      } else if (data is List) {
        itemsList = data;
      } else {
        itemsList = [];
      }
      return itemsList
          .whereType<Map<String, dynamic>>()
          .map((e) => PackageApiModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PackageApiModel> createPackage({
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await _dio.post(
        '/api/packages',
        data: {
          'categoryId': int.tryParse(categoryId),
          'name': name,
          'productLimit': productLimit,
          'description': description,
          'location': location,
          'stockStatus': stockStatus,
        },
        cancelToken: cancelToken,
      );
      final data = resp.data;
      Map<String, dynamic> json;
      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        json = inner is Map<String, dynamic> ? inner : data;
      } else {
        json = data as Map<String, dynamic>;
      }
      return PackageApiModel.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PackageApiModel> updatePackage({
    required String id,
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await _dio.patch(
        '/api/packages/$id',
        data: {
          'categoryId': int.tryParse(categoryId),
          'name': name,
          'productLimit': productLimit,
          'description': description,
          'location': location,
          'stockStatus': stockStatus,
        },
        cancelToken: cancelToken,
      );
      final data = resp.data;
      final Map<String, dynamic> json =
          data is Map<String, dynamic> ? data : data['data'] as Map<String, dynamic>;
      return PackageApiModel.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deletePackage(String id, {CancelToken? cancelToken}) async {
    try {
      await _dio.delete('/api/packages/$id', cancelToken: cancelToken);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
