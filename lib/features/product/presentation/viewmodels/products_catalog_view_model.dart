import 'dart:async';

import 'package:dio/dio.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';

class ProductsCatalogViewModel extends BaseViewModel {
  final Dio _dio;

  ProductsCatalogViewModel({Dio? dio})
      : _dio = dio ?? ApiClient.create();

  List<CategoryShowcaseData> _categories = [];
  List<CategoryShowcaseData> get categories => _categories;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Timer? _debounce;

  void setSearchQuery(String value) {
    _searchQuery = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      load();
    });
  }

  Future<void> load() async {
    if (isLoading) return;

    setLoading(true);
    resetError();

    try {
      final queryParams = <String, dynamic>{
        'productLimit': 4,
      };
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final response = await _dio.get(
        '/api/categories/with-products',
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );

      final data = response.data;
      final List<dynamic> items = data is Map ? (data['data'] ?? []) : (data as List? ?? []);

      _categories = items.map((json) {
        final cat = json as Map<String, dynamic>;
        final categoryId = cat['id']?.toString() ?? '';
        final categoryName = cat['name']?.toString() ?? '';
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
            imageUrl: product['image']?.toString().trim(),
            createdBy: product['createdBy']?.toString() ?? '',
          );
        }).toList();

        return CategoryShowcaseData(
          id: categoryId,
          name: categoryName,
          products: products,
        );
      }).toList();
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load categories: $e');
    } finally {
      setLoading(false);
    }
  }

  List<CatalogProductView> get hotProducts {
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
      await _dio.delete('/api/products/$productId', cancelToken: cancelToken);
      for (final cat in _categories) {
        cat.products.removeWhere((p) => p.id == productId);
      }
      _categories.removeWhere((c) => c.products.isEmpty);
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
