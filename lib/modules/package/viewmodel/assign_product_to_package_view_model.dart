import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/product/repository/catalog_product_repository.dart';

class AssignProductToPackageViewModel extends BaseViewModel {
  final CatalogProductRepository _productRepository;
  final Package package;

  AssignProductToPackageViewModel({
    required CatalogProductRepository productRepository,
    required this.package,
  }) : _productRepository = productRepository;

  List<CatalogProduct> _allProducts = [];
  List<CatalogProduct> get allProducts => _allProducts;

  List<String> _categories = ['All'];
  List<String> get categories => _categories;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  final Set<String> _selectedIds = {};
  Set<String> get selectedIds => _selectedIds;

  bool _isAssigning = false;
  bool get isAssigning => _isAssigning;

  int get selectedCount => _selectedIds.length;

  List<CatalogProduct> get filtered {
    return _allProducts.where((p) {
      final matchCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.brand.toLowerCase().contains(_searchQuery.toLowerCase());
      final hasNoPackage = p.packageId.isEmpty || p.packageId == '—';
      return matchCat && matchSearch && hasNoPackage;
    }).toList();
  }

  bool get allFilteredSelected {
    final items = filtered;
    return _selectedIds.length == items.length && items.isNotEmpty;
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSelectedCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void toggleSelect(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelectAll() {
    final items = filtered;
    if (_selectedIds.length == items.length) {
      _selectedIds.clear();
    } else {
      _selectedIds.addAll(items.map((p) => p.id));
    }
    notifyListeners();
  }

  Future<void> loadProducts() async {
    setLoading(true);
    resetError();
    try {
      _allProducts = await _productRepository.getProducts(cancelToken: cancelToken);
      _categories = [
        'All',
        ..._allProducts
            .map((p) => p.category)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList(),
      ];
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load products: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<int> assignToPackage() async {
    if (_selectedIds.isEmpty) return 0;

    _isAssigning = true;
    resetError();
    notifyListeners();

    try {
      final dio = ApiClient.create();
      int successCount = 0;

      for (final productId in _selectedIds) {
        try {
          await dio.put(
            '/api/products/$productId',
            data: {'packageId': int.tryParse(package.id)},
            cancelToken: cancelToken,
          );
          successCount++;
        } catch (_) {
          // Continue with other products
        }
      }

      _isAssigning = false;
      notifyListeners();
      return successCount;
    } on ApiException catch (e) {
      setError(e.message);
      _isAssigning = false;
      notifyListeners();
      return 0;
    } catch (e) {
      setError('Failed to assign products: $e');
      _isAssigning = false;
      notifyListeners();
      return 0;
    }
  }
}
