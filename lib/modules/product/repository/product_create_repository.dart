import '../model/product_create_models.dart';

abstract class ProductCreateRepository {
  Future<List<SupplierOption>> getSuppliers();
  Future<List<PackageOption>> getPackages();
  Future<ProductCreateRequest> createProduct(ProductCreateRequest request);
}
