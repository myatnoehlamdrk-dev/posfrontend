import 'package:posfrontend/features/category/domain/entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories({String? type, String? inventoryId});
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
}
