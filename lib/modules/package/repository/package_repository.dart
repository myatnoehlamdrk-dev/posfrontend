import 'package:posfrontend/modules/package/model/package_models.dart';

abstract class PackageRepository {
  List<Package> getPackages(String categoryId);
}
