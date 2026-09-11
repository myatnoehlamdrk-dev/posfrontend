import 'package:dio/dio.dart';
import 'package:posfrontend/core/extensions/api_response_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/package/repository/package_repository.dart';

class PackageRepositoryImpl implements PackageRepository {
  @override
  Future<List<Package>> getPackages(String categoryId) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get(
        '/api/packages',
        queryParameters: {'categoryId': categoryId},
      );
      return parseTypedList(resp.data, Package.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Package> createPackage({
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
  }) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.post(
        '/api/packages',
        data: {
          'categoryId': int.tryParse(categoryId),
          'name': name,
          'productLimit': productLimit,
          'description': description,
          'location': location,
          'stockStatus': stockStatus,
        },
      );
      final data = parseApiList(resp.data);
      final Map<String, dynamic> json = data.isNotEmpty
          ? data.first as Map<String, dynamic>
          : resp.data as Map<String, dynamic>;
      return Package.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Package> updatePackage({
    required String id,
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
  }) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.put(
        '/api/packages/$id',
        data: {
          'categoryId': int.tryParse(categoryId),
          'name': name,
          'productLimit': productLimit,
          'description': description,
          'location': location,
          'stockStatus': stockStatus,
        },
      );
      final data = resp.data;
      final Map<String, dynamic> json =
          data is Map<String, dynamic> ? data : data['data'] as Map<String, dynamic>;
      return Package.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
