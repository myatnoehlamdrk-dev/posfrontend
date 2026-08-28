import 'package:posfrontend/modules/category/model/category_models.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories({String? type, String? inventoryId});
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
  });
}
