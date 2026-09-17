import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/package/domain/repositories/package_repository.dart';

enum PackageSort {
  dateNewest,
  dateOldest,
  nameAz,
  nameZa,
}

class PackageViewModel extends BaseViewModel {
  final PackageRepository _repository;
  final String categoryId;

  List<PackageEntity> _packages = [];
  String _search = '';
  PackageSort _sort = PackageSort.dateNewest;

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
      _packages = await _repository.getPackages(categoryId, cancelToken: cancelToken);
    } on ApiException catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
    notifyListeners();
  }

  List<PackageEntity> get filtered {
    final q = _search.toLowerCase();
    final list = _packages.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case PackageSort.nameAz:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case PackageSort.nameZa:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case PackageSort.dateNewest:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case PackageSort.dateOldest:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
    return list;
  }

  int get total => _packages.length;
  String get search => _search;
  PackageSort get sort => _sort;

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setSort(PackageSort value) {
    _sort = value;
    notifyListeners();
  }

  void addPackage(PackageEntity package) {
    _packages.add(package);
    notifyListeners();
  }

  void updatePackage(PackageEntity updated) {
    final idx = _packages.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _packages[idx] = updated;
      notifyListeners();
    }
  }
}
