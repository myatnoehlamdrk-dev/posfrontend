import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository.dart';
import 'package:posfrontend/modules/inventory/repository/inventory_repository.dart';

enum CategorySort {
  dateNewest,
  dateOldest,
  nameAz,
  nameZa,
}

class CategoryViewModel extends BaseViewModel {
  final CategoryRepository _repository;
  final InventoryRepository _inventoryRepository;
  final String type;
  List<Category> _categories = [];

  String _search = '';
  String _status = 'All Status';
  CategorySort _sort = CategorySort.dateNewest;

  CategoryViewModel({
    required CategoryRepository repository,
    required InventoryRepository inventoryRepository,
    this.type = 'self',
  })  : _repository = repository,
        _inventoryRepository = inventoryRepository {
    load();
  }

  Future<void> load() async {
    setLoading(true);
    resetError();
    try {
      String? inventoryId;
      try {
        final inventory = await _inventoryRepository.getInventoryByType(type);
        inventoryId = inventory.id;
      } on ApiException {
        inventoryId = null;
      }

      _categories = await _repository.getCategories(
        inventoryId: inventoryId,
        type: type,
      );
    } on ApiException catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
    notifyListeners();
  }

  List<Category> get filtered {
    final q = _search.toLowerCase();
    final list = _categories.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(q);
      final matchesStatus =
          _status == 'All Status' ||
          (_status == 'Active' && c.active) ||
          (_status == 'Inactive' && !c.active);
      return matchesSearch && matchesStatus;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case CategorySort.nameAz:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case CategorySort.nameZa:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case CategorySort.dateNewest:
          return (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0));
        case CategorySort.dateOldest:
          return (a.createdAt ?? DateTime(0))
              .compareTo(b.createdAt ?? DateTime(0));
      }
    });
    return list;
  }

  int get totalCount => _categories.length;

  CategorySort get sort => _sort;
  String get search => _search;
  String get status => _status;

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setStatus(String value) {
    _status = value;
    notifyListeners();
  }

  void setSort(CategorySort value) {
    _sort = value;
    notifyListeners();
  }

  void addCategory(Category category) {
    _categories.add(category);
    notifyListeners();
  }
}
