import 'package:dio/dio.dart';
import 'package:posfrontend/features/package/data/datasources/package_remote_data_source.dart';
import 'package:posfrontend/features/package/data/models/package_api_model.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/package/domain/repositories/package_repository.dart';

class PackageRepositoryImpl implements PackageRepository {
  final PackageRemoteDataSource _dataSource;

  PackageRepositoryImpl({PackageRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? PackageRemoteDataSource();

  @override
  Future<List<PackageEntity>> getPackages(String categoryId, {CancelToken? cancelToken}) async {
    final models = await _dataSource.getPackages(categoryId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<PackageEntity> createPackage({
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
    CancelToken? cancelToken,
  }) async {
    final model = await _dataSource.createPackage(
      categoryId: categoryId,
      name: name,
      productLimit: productLimit,
      description: description,
      location: location,
      stockStatus: stockStatus,
    );
    return model.toEntity();
  }

  @override
  Future<PackageEntity> updatePackage({
    required String id,
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
    CancelToken? cancelToken,
  }) async {
    final model = await _dataSource.updatePackage(
      id: id,
      categoryId: categoryId,
      name: name,
      productLimit: productLimit,
      description: description,
      location: location,
      stockStatus: stockStatus,
    );
    return model.toEntity();
  }

  @override
  Future<void> deletePackage(String id) {
    return _dataSource.deletePackage(id);
  }
}
