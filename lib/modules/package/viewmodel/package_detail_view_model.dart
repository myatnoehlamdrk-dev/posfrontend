import 'package:flutter/material.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/product/repository/catalog_product_repository.dart';

class PackageDetailViewModel extends BaseViewModel {
  final CatalogProductRepository _productRepository;
  final Package package;
  final CategoryInfo category;

  PackageDetailViewModel({
    required CatalogProductRepository productRepository,
    required this.package,
    required this.category,
  }) : _productRepository = productRepository;

  List<CatalogProduct> _products = [];
  List<CatalogProduct> get products => _products;

  int get totalUnits => _products.fold(0, (sum, p) => sum + p.stock);

  StockStatus get computedStatus {
    final limit = package.productLimit;
    final qty = package.quantity;
    if (limit <= 0 || qty == 0) return StockStatus.outOfStock;
    final pct = (qty / limit) * 100;
    if (pct >= 70) return StockStatus.highStock;
    if (pct >= 30) return StockStatus.midStock;
    return StockStatus.lowStock;
  }

  String get stockLabel => stockStatusToString(computedStatus);

  int get stockPct {
    final limit = package.productLimit;
    if (limit <= 0) return 0;
    return ((package.quantity / limit) * 100).round().clamp(0, 100);
  }

  Future<void> load() async {
    setLoading(true);
    resetError();
    try {
      _products = await _productRepository.getProducts(
        packageId: package.id,
        cancelToken: cancelToken,
      );
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load products: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<bool> removeProduct(CatalogProduct product) async {
    try {
      final dio = ApiClient.create();
      await dio.put(
        '/api/products/${product.id}',
        data: {'packageId': null},
        cancelToken: cancelToken,
      );
      await load();
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Failed to remove product: $e');
      return false;
    }
  }
}

class CategoryInfo {
  final String name;
  final Color iconColor;
  final IconData icon;
  final String? imageUrl;

  const CategoryInfo({
    required this.name,
    required this.iconColor,
    required this.icon,
    this.imageUrl,
  });
}
