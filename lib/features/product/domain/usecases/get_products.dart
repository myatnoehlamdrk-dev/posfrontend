import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';
import 'package:posfrontend/features/product/domain/repositories/product_repository.dart';

class GetProductsUseCase extends UseCase<List<ProductEntity>, GetProductsParams> {
  final ProductRepository _repository;

  GetProductsUseCase(this._repository);

  @override
  Future<List<ProductEntity>> call(GetProductsParams params) {
    return _repository.getProducts(packageId: params.packageId);
  }
}

class GetProductsParams {
  final String? packageId;
  const GetProductsParams({this.packageId});
}

class DeleteProductUseCase extends UseCase<void, String> {
  final ProductRepository _repository;

  DeleteProductUseCase(this._repository);

  @override
  Future<void> call(String productId) {
    return _repository.deleteProduct(productId);
  }
}
