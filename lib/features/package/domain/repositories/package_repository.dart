import 'package:dio/dio.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';

abstract class PackageRepository {
  Future<List<PackageEntity>> getPackages(String categoryId, {CancelToken? cancelToken});
  Future<PackageEntity> createPackage({
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
    CancelToken? cancelToken,
  });
  Future<PackageEntity> updatePackage({
    required String id,
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
    CancelToken? cancelToken,
  });
  Future<void> deletePackage(String id);
}
