import 'package:dio/dio.dart';
import 'package:posfrontend/core/extensions/api_response_extensions.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/category/data/models/category_api_model.dart';

class CategoryRemoteDataSource {
  final Dio _dio;
  CategoryRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.create();

  /// One page of categories, with the counts the paginator needs.
  ///
  /// Separate from [getCategories] on purpose: that one answers "give me the
  /// list" for dropdowns and must keep returning a plain list, while this one
  /// answers "give me page N and how many pages there are" for the screen.
  Future<PaginatedResponse<CategoryApiModel>> getCategoriesPage({
    String? type,
    String? inventoryId,
    int page = 1,
    int perPage = 20,
    CancelToken? cancelToken,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (inventoryId != null) queryParameters['inventoryId'] = inventoryId;
    if (type != null) queryParameters['type'] = type;

    final resp = await _dio.get(
      '/categories',
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );

    final body = resp.data;
    if (body is Map<String, dynamic>) {
      return PaginatedResponse.fromJson(body, CategoryApiModel.fromJson);
    }

    // A server that has not been updated answers with a bare array and no
    // meta. Treating it as a single page keeps the screen usable instead of
    // throwing on a shape it was never taught to expect.
    final models = parseTypedList(body, CategoryApiModel.fromJson);
    return PaginatedResponse(
      data: models,
      lastPage: 1,
      currentPage: page,
      total: models.length,
    );
  }

  Future<List<CategoryApiModel>> getCategories({
    String? type,
    String? inventoryId,
    CancelToken? cancelToken,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (inventoryId != null) queryParameters['inventoryId'] = inventoryId;
    if (type != null) queryParameters['type'] = type;
    final resp = await _dio.get(
      '/categories',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      cancelToken: cancelToken,
    );
    return parseTypedList(resp.data, CategoryApiModel.fromJson);
  }

  Future<CategoryApiModel> getCategoryById(
    String id, {
    CancelToken? cancelToken,
  }) async {
    final resp = await _dio.get('/categories/$id', cancelToken: cancelToken);
    final data = resp.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      return CategoryApiModel.fromJson(
        inner is Map<String, dynamic> ? inner : data,
      );
    }
    return CategoryApiModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CategoryApiModel> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
    CancelToken? cancelToken,
  }) async {
    final resp = await _dio.post(
      '/categories',
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
      '/categories/$id',
      data: {
        'name': name,
        'description': description,
        'packageLimit': packageLimit,
      },
      cancelToken: cancelToken,
    );
    final data = resp.data;
    final Map<String, dynamic> json = data is Map<String, dynamic>
        ? data
        : data['data'] as Map<String, dynamic>;
    return CategoryApiModel.fromJson(json);
  }

  Future<void> deleteCategory(String id, {CancelToken? cancelToken}) async {
    await _dio.delete('/categories/$id', cancelToken: cancelToken);
  }
}
