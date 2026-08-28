import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/package/repository/package_repository.dart';

class PackageRepositoryImpl implements PackageRepository {
  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      return inner is List ? inner : [];
    }
    return [];
  }

  @override
  Future<List<Package>> getPackages(String categoryId) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.get(
        '/api/packages',
        queryParameters: {'categoryId': categoryId},
      );
      final data = _asList(resp.data);
      return data
          .map((e) => Package.fromJson(e as Map<String, dynamic>))
          .toList();
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
      final data = _asList(resp.data);
      final Map<String, dynamic> json = data.isNotEmpty
          ? data.first as Map<String, dynamic>
          : resp.data as Map<String, dynamic>;
      return Package.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
