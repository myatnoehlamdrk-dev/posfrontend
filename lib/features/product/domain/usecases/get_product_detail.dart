import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/product/domain/entities/product_detail.dart';
import 'package:posfrontend/features/product/domain/repositories/product_detail_repository.dart';

class GetProductDetailUseCase extends UseCase<ProductDetailEntity, String> {
  final ProductDetailRepository _repository;

  GetProductDetailUseCase(this._repository);

  @override
  Future<ProductDetailEntity> call(String productId) {
    return _repository.getDetail(productId);
  }
}
