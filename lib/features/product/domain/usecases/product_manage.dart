import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';
import 'package:posfrontend/features/product/domain/repositories/product_manage_repository.dart';

class SearchProductsUseCase extends UseCase<List<ProductEntity>, String> {
  final ProductManageRepository _repository;

  SearchProductsUseCase(this._repository);

  @override
  Future<List<ProductEntity>> call(String query) {
    return _repository.searchProducts(query);
  }
}

class GetSuppliersUseCase extends UseCase<List<Map<String, dynamic>>, NoParams> {
  final ProductManageRepository _repository;

  GetSuppliersUseCase(this._repository);

  @override
  Future<List<Map<String, dynamic>>> call(NoParams params) {
    return _repository.getSuppliers();
  }
}

class GetPackagesForProductUseCase extends UseCase<List<Map<String, dynamic>>, NoParams> {
  final ProductManageRepository _repository;

  GetPackagesForProductUseCase(this._repository);

  @override
  Future<List<Map<String, dynamic>>> call(NoParams params) {
    return _repository.getPackages();
  }
}

class CreateProductUseCase extends UseCase<void, Map<String, dynamic>> {
  final ProductManageRepository _repository;

  CreateProductUseCase(this._repository);

  @override
  Future<void> call(Map<String, dynamic> data) {
    return _repository.createProduct(data);
  }
}

class UpdateProductUseCase extends UseCase<void, UpdateProductParams> {
  final ProductManageRepository _repository;

  UpdateProductUseCase(this._repository);

  @override
  Future<void> call(UpdateProductParams params) {
    return _repository.updateProduct(params.productId, params.data);
  }
}

class UpdateProductParams {
  final String productId;
  final Map<String, dynamic> data;
  const UpdateProductParams({required this.productId, required this.data});
}
