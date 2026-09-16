import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/product/repository/catalog_product_repository.dart';

enum ProductSort {
  dateNewest,
  dateOldest,
  nameAz,
  nameZa,
  priceLow,
  priceHigh,
}

class ProductsCatalogViewModel extends BaseViewModel {
  final CatalogProductRepository _repository;

  ProductsCatalogViewModel({required CatalogProductRepository repository})
      : _repository = repository;

  List<CatalogProduct> _allProducts = [];
  List<CatalogProduct> get allProducts => _allProducts;

  String _category = 'All';
  String get category => _category;

  ProductSort _sort = ProductSort.dateNewest;
  ProductSort get sort => _sort;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<String> get filters {
    final cats = <String>{
      for (final p in _allProducts)
        if (p.category.isNotEmpty) p.category,
    };
    final sorted = cats.toList()..sort();
    return ['All', ...sorted];
  }

  List<CatalogProduct> get filtered {
    final q = _searchQuery.toLowerCase();
    final list = _allProducts.where((p) {
      final matchesCat = _category == 'All' || p.category == _category;
      final matchesSearch =
          q.isEmpty || p.name.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case ProductSort.nameAz:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ProductSort.nameZa:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case ProductSort.priceLow:
          return a.price.compareTo(b.price);
        case ProductSort.priceHigh:
          return b.price.compareTo(a.price);
        case ProductSort.dateNewest:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case ProductSort.dateOldest:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
    return list;
  }

  List<CatalogProduct> get hotProducts {
    final list = List<CatalogProduct>.from(_allProducts);
    return list.length > 4 ? list.sublist(0, 4) : list;
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setSort(ProductSort value) {
    _sort = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> load() async {
    setLoading(true);
    resetError();
    try {
      _allProducts = await _repository.getProducts(cancelToken: cancelToken);
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load products: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      final dio = ApiClient.create();
      await dio.delete('/api/products/$productId', cancelToken: cancelToken);
      _allProducts.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Failed to delete product: $e');
      return false;
    }
  }
}
