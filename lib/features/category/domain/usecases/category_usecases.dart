import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';

class GetCategoriesUseCase
    extends UseCase<List<Category>, GetCategoriesParams> {
  final CategoryRepository _repository;
  GetCategoriesUseCase(this._repository);

  @override
  Future<List<Category>> call(GetCategoriesParams params) {
    return _repository.getCategories(
      type: params.type,
      inventoryId: params.inventoryId,
    );
  }
}

class GetCategoriesParams {
  final String? type;
  final String? inventoryId;
  const GetCategoriesParams({this.type, this.inventoryId});
}

class CreateCategoryUseCase
    extends UseCase<Category, CreateCategoryParams> {
  final CategoryRepository _repository;
  CreateCategoryUseCase(this._repository);

  @override
  Future<Category> call(CreateCategoryParams params) {
    return _repository.createCategory(
      type: params.type,
      name: params.name,
      description: params.description,
      packageLimit: params.packageLimit,
    );
  }
}

class CreateCategoryParams {
  final String type;
  final String name;
  final String? description;
  final int? packageLimit;
  const CreateCategoryParams({
    required this.type,
    required this.name,
    this.description,
    this.packageLimit,
  });
}

class UpdateCategoryUseCase
    extends UseCase<Category, UpdateCategoryParams> {
  final CategoryRepository _repository;
  UpdateCategoryUseCase(this._repository);

  @override
  Future<Category> call(UpdateCategoryParams params) {
    return _repository.updateCategory(
      id: params.id,
      name: params.name,
      description: params.description,
      packageLimit: params.packageLimit,
    );
  }
}

class UpdateCategoryParams {
  final String id;
  final String name;
  final String? description;
  final int? packageLimit;
  const UpdateCategoryParams({
    required this.id,
    required this.name,
    this.description,
    this.packageLimit,
  });
}
