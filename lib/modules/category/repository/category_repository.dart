import 'package:dio/dio.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories({String? type, String? inventoryId, CancelToken? cancelToken});
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
    CancelToken? cancelToken,
  });
  Future<Category> updateCategory({
    required String id,
    required String name,
    String? description,
    int? packageLimit,
    CancelToken? cancelToken,
  });
}
