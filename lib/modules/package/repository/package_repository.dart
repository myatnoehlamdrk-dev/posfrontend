import 'package:posfrontend/modules/package/model/package_models.dart';

abstract class PackageRepository {
  Future<List<Package>> getPackages(String categoryId);
  Future<Package> createPackage({
    required String categoryId,
    required String name,
    int? productLimit,
    String? description,
    String? location,
    String? stockStatus,
  });
}
