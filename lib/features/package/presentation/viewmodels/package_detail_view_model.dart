import 'package:flutter/material.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/product/domain/repositories/product_repository.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';

class PackageDetailViewModel extends BaseViewModel {
  final ProductRepository _productRepository;
  final PackageEntity package;
  final CategoryInfo category;

  PackageDetailViewModel({
    required ProductRepository productRepository,
    required this.package,
    required this.category,
  }) : _productRepository = productRepository;

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
      final response = await _productRepository.getProducts(
        packageId: package.id,
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
        final price = (map['stock'] as num?)?.toDouble() ?? 0.0;
        final stock = (map['stock'] as num?)?.toInt() ?? 0;
        final isSet = map['isSet'] == true;
        final category = map['category']?.toString() ?? '';
        final packageId = map['packageId']?.toString() ?? '';
        final imageUrl = resolveMediaUrl(map['image']?.toString().trim());
        final createdBy = map['createdBy']?.toString() ?? '';
        final variantsRaw = map['variants'];
        final variantList = variantsRaw is List ? variantsRaw : [];
        return CatalogProductView(
          id: id,
          name: name,
          brand: brand,
          sku: sku,
          price: price,
          stock: stock,
          isSet: isSet,
          category: category,
          packageId: packageId,
          icon: CatalogProductView.iconFor(name),
          color: CatalogProductView.colorFor(name),
          imageUrl: imageUrl,
          variants: variantList.map((v) {
            final vm = v as Map<String, dynamic>;
            return ProductVariant(
              size: (vm['size'] as String?)?.trim() ?? '',
              color: (vm['color'] as String?)?.trim() ?? '',
              quantity: (vm['quantity'] as num?)?.toInt() ?? 0,
              price: (vm['price'] as num?)?.toDouble() ?? 0,
            );
          }).toList(),
          createdBy: createdBy,
        );
      }).toList();
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load products: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<bool> removeProduct(CatalogProductView product) async {
    try {
      final dio = ApiClient.create();
      await dio.patch(
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
