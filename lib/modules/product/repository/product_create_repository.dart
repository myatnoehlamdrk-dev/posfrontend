import '../model/product_create_models.dart';

abstract class ProductCreateRepository {
  Future<List<SupplierOption>> getSuppliers();
  Future<List<PackageOption>> getPackages(String categoryId);
  Future<void> createProduct(ProductCreateRequest request);
  Future<void> updateProduct(String id, ProductCreateRequest request);
  Future<List<ProductSearchResult>> searchProducts(String query);
  Future<List<PendingPurchaseItem>> getPendingPurchaseItems();
  Future<void> completePurchaseItem(String id);
}
