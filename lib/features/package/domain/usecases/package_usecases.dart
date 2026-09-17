import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/package/domain/repositories/package_repository.dart';

class GetPackagesUseCase {
  final PackageRepository _repository;

  GetPackagesUseCase(this._repository);

  Future<List<PackageEntity>> call(String categoryId) =>
      _repository.getPackages(categoryId);
}

class CreatePackageUseCase {
  final PackageRepository _repository;

  CreatePackageUseCase(this._repository);

  Future<PackageEntity> call({
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
  }) =>
      _repository.createPackage(
        categoryId: categoryId,
        name: name,
        productLimit: productLimit,
        description: description,
        location: location,
        stockStatus: stockStatus,
      );
}

class UpdatePackageUseCase {
  final PackageRepository _repository;

  UpdatePackageUseCase(this._repository);

  Future<PackageEntity> call({
    required String id,
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
  }) =>
      _repository.updatePackage(
        id: id,
        categoryId: categoryId,
        name: name,
        productLimit: productLimit,
        description: description,
        location: location,
        stockStatus: stockStatus,
      );
}
