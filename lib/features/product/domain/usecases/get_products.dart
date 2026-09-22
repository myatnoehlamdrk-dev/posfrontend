import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';
import 'package:posfrontend/features/product/domain/repositories/product_repository.dart';

class GetProductsUseCase extends UseCase<Map<String, dynamic>, GetProductsParams> {
  final ProductRepository _repository;

  GetProductsUseCase(this._repository);

  @override
  Future<Map<String, dynamic>> call(GetProductsParams params) {
    return _repository.getProducts(
      packageId: params.packageId,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

class GetProductsParams {
  final String? packageId;
  final int page;
  final int perPage;
  const GetProductsParams({
    this.packageId,
    this.page = 1,
    this.perPage = 10,
  });
}

class DeleteProductUseCase extends UseCase<void, String> {
  final ProductRepository _repository;

  DeleteProductUseCase(this._repository);

  @override
  Future<void> call(String productId) {
    return _repository.deleteProduct(productId);
  }
}
