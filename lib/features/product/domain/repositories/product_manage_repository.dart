import 'package:posfrontend/features/product/domain/entities/product.dart';
import 'package:posfrontend/features/product/domain/entities/category.dart';

abstract class ProductManageRepository {
  Future<List<Map<String, dynamic>>> getSuppliers();
  Future<List<Map<String, dynamic>>> getPackages();
  Future<void> createProduct(Map<String, dynamic> data);
  Future<void> updateProduct(String productId, Map<String, dynamic> data);
  Future<List<ProductEntity>> searchProducts(String query);
  Future<List<Map<String, dynamic>>> getPendingPurchaseItems();
  Future<void> completePurchaseItem(String itemId);
}

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories();
  Future<void> createCategory({required String name, String? description, String? inventoryId, String? type});
  Future<void> updateCategory(String id, {String? name, String? description, bool? active});
}
