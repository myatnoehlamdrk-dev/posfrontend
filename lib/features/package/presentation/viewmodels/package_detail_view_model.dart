import 'package:flutter/material.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/package/domain/repositories/package_repository.dart';
import 'package:posfrontend/features/product/domain/repositories/product_repository.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';

class PackageDetailViewModel extends BaseViewModel {
  final ProductRepository _productRepository;
  final PackageRepository _packageRepository;

  /// Replaced by [_refreshPackage] on every load: the entity the previous
  /// screen passed in carries the product count from whenever it was listed,
  /// which stops being true the moment a product is added or removed here.
  PackageEntity package;
  final CategoryInfo category;

  PackageDetailViewModel({
    required ProductRepository productRepository,
    required PackageRepository packageRepository,
    required this.package,
    required this.category,
  })  : _productRepository = productRepository,
        _packageRepository = packageRepository;

  List<CatalogProductView> _products = [];
  List<CatalogProductView> get products => _products;

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
      // perPage 1000: the old default of 10 cut every package off at its ten
      // newest products (and made the header count wrong with it).
      // preferNetwork: this screen's whole job is to display and edit which
      // products are in the package, so the cache never gets to answer first.
      final response = await _productRepository.getProducts(
        packageId: package.id,
        perPage: 1000,
        preferNetwork: true,
        cancelToken: cancelToken,
      );
      final rawList = response['data'];
      final List<dynamic> items = rawList is List ? rawList : [];
      _products = items.map((json) {
        final map = json as Map<String, dynamic>;
        final id = map['id']?.toString() ?? '';
        final name = map['name']?.toString() ?? '';
        final brand = map['brand']?.toString() ?? '';
        final sku = map['sku']?.toString() ?? '';
        final stock = (map['stock'] as num?)?.toInt() ?? 0;
        final isSet = map['isSet'] == true;
        final category = map['category']?.toString() ?? '';
        final packageId = map['packageId']?.toString() ?? '';
        final imageUrl = resolveMediaUrl(map['image']?.toString().trim());
        final createdBy = map['createdBy']?.toString() ?? '';
        final variantsRaw = map['variants'];
        final variantList = variantsRaw is List ? variantsRaw : [];
        final variants = variantList.map((v) {
          final vm = v as Map<String, dynamic>;
          return ProductVariant(
            size: (vm['size'] as String?)?.trim() ?? '',
            color: (vm['color'] as String?)?.trim() ?? '',
            quantity: (vm['quantity'] as num?)?.toInt() ?? 0,
            price: (vm['price'] as num?)?.toDouble() ?? 0,
          );
        }).toList();
        return CatalogProductView(
          id: id,
          name: name,
          brand: brand,
          sku: sku,
          // ProductResource has no top-level price — variants carry it. (The
          // old mapping read `stock` instead, so a product's "price" was its
          // stock count.)
          price: variants.isNotEmpty ? variants.first.price : 0.0,
          stock: stock,
          isSet: isSet,
          category: category,
          packageId: packageId,
          icon: CatalogProductView.iconFor(name),
          color: CatalogProductView.colorFor(name),
          imageUrl: imageUrl,
          variants: variants,
          createdBy: createdBy,
        );
      }).toList();

      await _refreshPackage();
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load products: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Re-fetches the package header (product count, stock status, attribution)
  /// after the product list, so adding or removing a product updates the
  /// summary card and stock bar instead of leaving the values this screen was
  /// opened with. Best effort: failing (offline) keeps the stale-but-usable
  /// entity rather than failing the whole screen — the products already came
  /// from cache in that case.
  Future<void> _refreshPackage() async {
    try {
      package = await _packageRepository.getPackageById(
        package.id,
        cancelToken: cancelToken,
      );
    } catch (_) {
      // Keep the entity we were opened with.
    }
  }

  Future<bool> removeProduct(CatalogProductView product) async {
    try {
      await _productRepository.setProductPackage(
        product.id,
        null,
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
