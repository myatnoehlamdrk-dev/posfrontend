import 'package:posfrontend/modules/category/model/category_models.dart';

abstract class CategoryRepository {
  List<Category> getCategories();
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? amountOfPackage,
  });
}
