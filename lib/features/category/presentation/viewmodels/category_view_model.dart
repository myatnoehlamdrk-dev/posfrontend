import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';
import 'package:posfrontend/features/inventory/domain/repositories/inventory_repository.dart';

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
    CategoryRepository? repository,
    InventoryRepository? inventoryRepository,
    this.type = 'self',
  })  : _repository = repository ?? _defaultCategoryRepository(),
        _inventoryRepository = inventoryRepository ?? _defaultInventoryRepository() {
    load();
  }

  static CategoryRepository _defaultCategoryRepository() {
    throw UnimplementedError(
        'CategoryRepository must be injected into CategoryViewModel');
  }

  static InventoryRepository _defaultInventoryRepository() {
    throw UnimplementedError(
        'InventoryRepository must be injected into CategoryViewModel');
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
          return b.createdDate.compareTo(a.createdDate);
        case CategorySort.dateOldest:
          return a.createdDate.compareTo(b.createdDate);
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

  void updateCategory(Category updated) {
    final idx = _categories.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _categories[idx] = updated;
      notifyListeners();
    }
  }
}
