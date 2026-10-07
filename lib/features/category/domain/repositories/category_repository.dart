import 'package:dio/dio.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories({String? type, String? inventoryId});

  /// One page of categories plus the totals the paginator renders from.
  Future<PaginatedResponse<Category>> getCategoriesPage({
    String? type,
    String? inventoryId,
    int page = 1,
    int perPage = 20,
    CancelToken? cancelToken,
  });
  Future<Category> getCategoryById(String id, {CancelToken? cancelToken});
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
  });
  Future<Category> updateCategory({
    required String id,
    required String name,
    String? description,
    int? packageLimit,
  });
  Future<void> deleteCategory(String id);
}
