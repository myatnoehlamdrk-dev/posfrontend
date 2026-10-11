import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';
import 'package:posfrontend/features/inventory/domain/repositories/inventory_repository.dart';

enum CategorySort { dateNewest, dateOldest, nameAz, nameZa }

class CategoryViewModel extends BaseViewModel {
  final CategoryRepository _repository;
  final InventoryRepository _inventoryRepository;
  final String type;
  List<Category> _categories = [];

  /// Rows per page. Deliberately small: the pager only earns its space once
  /// a shop has more than one page, and 5 makes that show up long before the
  /// server's default of 20 would.
  static const int perPage = 5;

  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  CategorySort _sort = CategorySort.nameAz;

  CategoryViewModel({
    CategoryRepository? repository,
    InventoryRepository? inventoryRepository,
    this.type = 'self',
  }) : _repository = repository ?? _defaultCategoryRepository(),
       _inventoryRepository =
           inventoryRepository ?? _defaultInventoryRepository() {
    load();
  }

  static CategoryRepository _defaultCategoryRepository() {
    throw UnimplementedError(
      'CategoryRepository must be injected into CategoryViewModel',
    );
  }

  static InventoryRepository _defaultInventoryRepository() {
    throw UnimplementedError(
      'InventoryRepository must be injected into CategoryViewModel',
    );
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

      final page = await _repository.getCategoriesPage(
        inventoryId: inventoryId,
        type: type,
        page: _page,
        perPage: perPage,
        cancelToken: cancelToken,
      );

      _categories = page.data;
      _lastPage = page.lastPage < 1 ? 1 : page.lastPage;
      _total = page.total;
      // Deleting the tail of the list can leave the current page past the end;
      // clamping here keeps the label from advertising a page that no longer
      // exists. The next tap of Next/Prev refetches from the right place.
      if (_page > _lastPage) _page = _lastPage;
    } on ApiException catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
    notifyListeners();
  }

  int get currentPage => _page;
  int get lastPage => _lastPage;
  bool get canGoPrev => _page > 1 && !isLoading;
  bool get canGoNext => _page < _lastPage && !isLoading;

  /// Moves to [page], clamped to the loaded page count, and refetches.
  /// Selecting the page already showing is a no-op, so the buttons cannot
  /// trigger a redundant request.
  Future<void> goToPage(int page) async {
    if (isLoading) return;
    final target = page < 1
        ? 1
        : page > _lastPage
        ? _lastPage
        : page;
    if (target == _page) return;
    _page = target;
    await load();
  }

  Future<void> nextPage() => goToPage(_page + 1);
  Future<void> prevPage() => goToPage(_page - 1);

  List<Category> get filtered {
    final list = _categories.toList();

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

  /// The server's count for the whole set, not the length of the loaded page:
  /// the footer promises "First N of {total}" and N is capped by the page size.
  int get totalCount => _total;

  CategorySort get sort => _sort;

  void setSort(CategorySort value) {
    _sort = value;
    notifyListeners();
  }

  void addCategory(Category category) {
    _categories.add(category);
    _total++;
    notifyListeners();
  }

  void updateCategory(Category updated) {
    final idx = _categories.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _categories[idx] = updated;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      final dio = ApiClient.create();
      await dio.delete('/categories/$categoryId', cancelToken: cancelToken);
      _categories.removeWhere((c) => c.id == categoryId);
      if (_total > 0) _total--;

      // Emptied the last page by deleting its only row: step back rather than
      // leave the screen on a page the server no longer has.
      if (_categories.isEmpty && _page > 1) {
        notifyListeners();
        await goToPage(_page - 1);
        return true;
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Failed to delete category: $e');
      return false;
    }
  }
}
