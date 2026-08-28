import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/package/repository/package_repository.dart';

class PackageViewModel extends BaseViewModel {
  final PackageRepository _repository;
  final String categoryId;

  List<Package> _packages = [];
  String _search = '';

  PackageViewModel({
    required PackageRepository repository,
    required this.categoryId,
  })  : _repository = repository {
    load();
  }

  Future<void> load() async {
    setLoading(true);
    resetError();
    try {
      _packages = await _repository.getPackages(categoryId);
    } on ApiException catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
    notifyListeners();
  }

  List<Package> get filtered {
    final q = _search.toLowerCase();
    return _packages.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q);
    }).toList();
  }

  int get total => _packages.length;
  String get search => _search;

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void addPackage(Package package) {
    _packages.add(package);
    notifyListeners();
  }
}
