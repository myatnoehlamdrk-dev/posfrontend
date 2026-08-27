import '../model/product_create_models.dart';
import 'product_create_repository.dart';

class ProductCreateRepositoryImpl implements ProductCreateRepository {
  @override
  Future<List<SupplierOption>> getSuppliers() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return const [
      SupplierOption(id: 'SUP-001', name: 'TechSource Ltd'),
      SupplierOption(id: 'SUP-002', name: 'Global Components'),
      SupplierOption(id: 'SUP-003', name: 'Prime Electronics'),
      SupplierOption(id: 'SUP-004', name: 'Nordic Supply Co'),
    ];
  }

  @override
  Future<List<PackageOption>> getPackages() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return const [
      PackageOption(id: 'PKG-001', name: 'Audio Bundle A'),
      PackageOption(id: 'PKG-002', name: 'Charging Kit'),
      PackageOption(id: 'PKG-003', name: 'Peripheral Pack'),
    ];
  }

  @override
  Future<ProductCreateRequest> createProduct(ProductCreateRequest request) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return request;
  }
}
