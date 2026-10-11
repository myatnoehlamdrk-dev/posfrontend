import 'dart:async';

import 'package:dio/dio.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/package/data/models/package_api_model.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';

class ProductsCatalogViewModel extends BaseViewModel {
  final Dio _dio;

  ProductsCatalogViewModel({Dio? dio}) : _dio = dio ?? ApiClient.create();

  List<CategoryShowcaseData> _categories = [];
  List<CategoryShowcaseData> get categories => _categories;

  List<CatalogProductView> _hotProducts = [];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<CatalogProductView> _searchResults = [];
  List<CatalogProductView> get searchResults => _searchResults;

  bool _searchLoading = false;
  bool get searchLoading => _searchLoading;

  int _searchRevision = 0;
  bool _searchRequested = false;
  bool get searchRequested => _searchRequested;

  bool get isSearching => _searchQuery.trim().isNotEmpty;

  Timer? _debounce;

  void setSearchQuery(String value) {
    _searchQuery = value;
    if (value.trim().isEmpty) {
      _searchResults = [];
      _searchRequested = false;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (isSearching) {
        searchProducts();
      } else {
        load();
      }
    });
  }

  Future<void> refresh() async {
    if (isSearching) {
      await searchProducts();
    } else {
      await load();
    }
  }

  Future<void> searchProducts() async {
    final query = _searchQuery.trim();
    if (query.isEmpty) {
      load();
      return;
    }

    final rev = ++_searchRevision;
    _searchRequested = true;
    _searchResults = [];
    _setSearchLoading(true);
    resetError();

    try {
      final response = await _dio.get(
        '/products/search',
        queryParameters: {'q': query},
        cancelToken: cancelToken,
      );

      final List<dynamic> items = response.data is List
          ? response.data as List
          : (response.data is Map
                ? ((response.data as Map)['data'] as List? ?? const [])
                : const []);

      if (rev != _searchRevision) return;

      final parsed = items.whereType<Map<String, dynamic>>().map((product) {
        final category = product['category']?.toString() ?? '';
        return CatalogProductView(
          id: product['id']?.toString() ?? '',
          name: product['name']?.toString() ?? '',
          brand: product['brand']?.toString() ?? '',
          sku: product['sku']?.toString() ?? '',
          price: (product['variants'] as List?)?.isNotEmpty == true
              ? ((product['variants'] as List).first['price'] ?? 0).toDouble()
              : 0.0,
          stock: (product['stock'] as num?)?.toInt() ?? 0,
          isSet: product['isSet'] == true,
          category: category,
          packageId: product['packageId']?.toString() ?? '',
          icon: CatalogProductView.iconFor(category),
          color: CatalogProductView.colorFor(category),
          imageUrl: resolveMediaUrl(product['image']?.toString()),
          createdBy: product['createdBy']?.toString() ?? '',
        );
      }).toList();

      _searchResults = parsed;
      notifyListeners();
    } on ApiException catch (e) {
      if (rev == _searchRevision) setError(e.message);
    } catch (e) {
      if (rev == _searchRevision) setError('Failed to search products: $e');
    } finally {
      if (rev == _searchRevision) _setSearchLoading(false);
    }
  }

  void _setSearchLoading(bool value) {
    if (_searchLoading == value) return;
    _searchLoading = value;
    notifyListeners();
  }

  Future<void> load() async {
    if (isLoading) return;

    setLoading(true);
    resetError();

    try {
      final queryParams = <String, dynamic>{'productLimit': 4};
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final response = await _dio.get(
        '/categories/with-products',
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );

      final data = response.data;
      final List<dynamic> items = data is Map
          ? (data['data'] ?? [])
          : (data as List? ?? []);

      _categories = items.map((json) {
        final cat = json as Map<String, dynamic>;
        final categoryId = cat['id']?.toString() ?? '';
        final categoryName = cat['name']?.toString() ?? '';
        // The endpoint sends `description` alongside the name, but older
        // categories predate the column and come back null — hence the
        // `?? ''`. An empty description is a normal state, not an error.
        final categoryDescription = cat['description']?.toString() ?? '';
        final products = (cat['products'] as List? ?? []).map((p) {
          final product = p as Map<String, dynamic>;
          return CatalogProductView(
            id: product['id']?.toString() ?? '',
            name: product['name']?.toString() ?? '',
            brand: product['brand']?.toString() ?? '',
            sku: product['sku']?.toString() ?? '',
            price: (product['variants'] as List?)?.isNotEmpty == true
                ? ((product['variants'] as List).first['price'] ?? 0).toDouble()
                : 0.0,
            stock: (product['stock'] as num?)?.toInt() ?? 0,
            isSet: product['isSet'] == true,
            category: categoryName,
            packageId: product['packageId']?.toString() ?? '',
            icon: CatalogProductView.iconFor(categoryName),
            color: CatalogProductView.colorFor(categoryName),
            imageUrl: resolveMediaUrl(product['image']?.toString()),
            createdBy: product['createdBy']?.toString() ?? '',
          );
        }).toList();

        return CategoryShowcaseData(
          id: categoryId,
          name: categoryName,
          description: categoryDescription,
          products: products,
          productCount: _countFrom(cat, products.length),
        );
      }).toList();
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load categories: $e');
    } finally {
      setLoading(false);
    }

    await _loadHotProducts();
    await _loadPackages();
  }

  /// How many packages the "Explore Packages" band shows before it is expanded.
  ///
  /// Six is two rows of three on a phone, which is the most a shop owner will
  /// look at before deciding to tap through. The section is a way in, not the
  /// place packages are managed, so it shows a fixed number rather than offering
  /// to reveal the rest.
  static const int packagePreviewCount = 6;

  List<PackageEntity> _packages = [];

  /// Every package the shop owns that came back in the fetch, newest first.
  List<PackageEntity> get packages => _packages;

  Future<void> _loadPackages() async {
    try {
      // No `categoryId`: the endpoint falls back to every package in the shop,
      // which is what an "Explore" section wants. The page size is fixed at 20
      // server-side and cannot be narrowed by a query parameter, so the limit
      // is applied on the way into [packages] rather than at the network.
      final response = await _dio.get('/packages', cancelToken: cancelToken);

      final data = response.data;
      final List<dynamic> items = data is Map
          ? (data['data'] ?? [])
          : (data as List? ?? []);

      _packages = items
          .whereType<Map<String, dynamic>>()
          .map((json) => PackageApiModel.fromJson(json).toEntity())
          .toList();
      notifyListeners();
    } catch (e) {
      // Non-fatal, and deliberately not routed through setError: the catalog is
      // perfectly usable without the packages band, so a failure here must not
      // put an error message on a page that has no error to report.
    }
  }

  /// The category's real product total, if the endpoint reports one.
  ///
  /// `/categories/with-products` is called with a `productLimit`, so the
  /// embedded `products` array is a preview and its length is not the total.
  ///
  /// Every spelling that has carried this field is read, and the **largest**
  /// value wins — over the other spellings and over the loaded count. Taking
  int _countFrom(Map<String, dynamic> category, int loadedCount) {
    var best = loadedCount;
    for (final key in const [
      'productCount',
      'product_count',
      'productsCount',
      'products_count',
      'totalProducts',
      'total_products',
      'total',
    ]) {
      final value = category[key];
      if (value is num && value >= 0 && value.toInt() > best) {
        best = value.toInt();
      }
    }
    // If the API reports a lower or missing total but the category also
    // includes an embedded products list, trust what we actually loaded.
    final embedded = category['products'];
    if (embedded is List && embedded.length > best) {
      best = embedded.length;
    }
    return best;
  }



  Future<void> _loadHotProducts() async {
    try {
      final response = await _dio.get(
        '/products/latest',
        queryParameters: {'limit': 4},
        cancelToken: cancelToken,
      );

      final data = response.data;
      final List<dynamic> items = data is Map
          ? (data['data'] ?? [])
          : (data as List? ?? []);

      _hotProducts = items.map((p) {
        final product = p as Map<String, dynamic>;
        final category = product['category']?.toString() ?? '';
        return CatalogProductView(
          id: product['id']?.toString() ?? '',
          name: product['name']?.toString() ?? '',
          brand: product['brand']?.toString() ?? '',
          sku: product['sku']?.toString() ?? '',
          price: (product['variants'] as List?)?.isNotEmpty == true
              ? ((product['variants'] as List).first['price'] ?? 0).toDouble()
              : 0.0,
          stock: (product['stock'] as num?)?.toInt() ?? 0,
          isSet: product['isSet'] == true,
          category: category,
          packageId: product['packageId']?.toString() ?? '',
          icon: CatalogProductView.iconFor(category),
          color: CatalogProductView.colorFor(category),
          imageUrl: resolveMediaUrl(product['image']?.toString()),
          createdBy: product['createdBy']?.toString() ?? '',
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      // Non-fatal; the carousel falls back to category products.
    }
  }

  List<CatalogProductView> get hotProducts {
    if (_hotProducts.isNotEmpty) return _hotProducts;
    final allProducts = _categories.expand((c) => c.products).toList();
    return allProducts.length > 4 ? allProducts.sublist(0, 4) : allProducts;
  }

  List<String> get filters {
    final cats = <String>{
      for (final c in _categories)
        if (c.name.isNotEmpty && c.name != 'Uncategorized') c.name,
    };
    final sorted = cats.toList()..sort();
    return ['All', ...sorted];
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _dio.delete('/products/$productId', cancelToken: cancelToken);
      for (final cat in _categories) {
        cat.products.removeWhere((p) => p.id == productId);
      }
      _categories.removeWhere((c) => c.products.isEmpty);
      _searchResults.removeWhere((p) => p.id == productId);
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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
