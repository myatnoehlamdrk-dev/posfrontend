import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/product/domain/entities/category.dart';
import 'package:posfrontend/features/product/domain/repositories/product_manage_repository.dart';

class GetCategoriesUseCase extends UseCase<List<CategoryEntity>, NoParams> {
  final CategoryRepository _repository;

  GetCategoriesUseCase(this._repository);

  @override
  Future<List<CategoryEntity>> call(NoParams params) {
    return _repository.getCategories();
  }
}

class CreateCategoryUseCase extends UseCase<void, CreateCategoryParams> {
  final CategoryRepository _repository;

  CreateCategoryUseCase(this._repository);

  @override
  Future<void> call(CreateCategoryParams params) {
    return _repository.createCategory(
      name: params.name,
      description: params.description,
      inventoryId: params.inventoryId,
      type: params.type,
    );
  }
}

class CreateCategoryParams {
  final String name;
  final String? description;
  final String? inventoryId;
  final String? type;
  const CreateCategoryParams({required this.name, this.description, this.inventoryId, this.type});
}

class UpdateCategoryUseCase extends UseCase<void, UpdateCategoryParams> {
  final CategoryRepository _repository;

  UpdateCategoryUseCase(this._repository);

  @override
  Future<void> call(UpdateCategoryParams params) {
    return _repository.updateCategory(params.id, name: params.name, description: params.description, active: params.active);
  }
}

class UpdateCategoryParams {
  final String id;
  final String? name;
  final String? description;
  final bool? active;
  const UpdateCategoryParams({required this.id, this.name, this.description, this.active});
}
