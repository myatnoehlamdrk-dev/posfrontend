import 'package:dio/dio.dart';
import 'package:posfrontend/core/extensions/api_response_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/category/data/models/category_api_model.dart';

class CategoryRemoteDataSource {
  final Dio _dio;
  CategoryRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<List<CategoryApiModel>> getCategories({
    String? type,
    String? inventoryId,
    CancelToken? cancelToken,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (inventoryId != null) queryParameters['inventoryId'] = inventoryId;
    if (type != null) queryParameters['type'] = type;
    final resp = await _dio.get(
      '/api/categories',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      cancelToken: cancelToken,
    );
    return parseTypedList(resp.data, CategoryApiModel.fromJson);
  }

  Future<CategoryApiModel> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
    CancelToken? cancelToken,
  }) async {
    final resp = await _dio.post(
      '/api/categories',
      data: {
        'type': type,
        'name': name,
        'description': description,
        'packageLimit': packageLimit,
      },
      cancelToken: cancelToken,
    );
    final json = resp.data as Map<String, dynamic>;
    return CategoryApiModel.fromJson(json);
  }

  Future<CategoryApiModel> updateCategory({
    required String id,
    required String name,
    String? description,
    int? packageLimit,
    CancelToken? cancelToken,
  }) async {
    final resp = await _dio.patch(
      '/api/categories/$id',
      data: {
        'name': name,
        'description': description,
        'packageLimit': packageLimit,
      },
      cancelToken: cancelToken,
    );
    final data = resp.data;
    final Map<String, dynamic> json =
        data is Map<String, dynamic> ? data : data['data'] as Map<String, dynamic>;
    return CategoryApiModel.fromJson(json);
  }

  Future<void> deleteCategory(String id, {CancelToken? cancelToken}) async {
    await _dio.delete('/api/categories/$id', cancelToken: cancelToken);
  }
}
