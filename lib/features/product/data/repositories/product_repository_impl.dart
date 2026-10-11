import 'package:dio/dio.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/features/product/data/datasources/product_local_data_source.dart';
import 'package:posfrontend/features/product/data/datasources/product_remote_data_source.dart';
import 'package:posfrontend/features/product/data/models/product_api_model.dart';
import 'package:posfrontend/features/product/data/models/product_detail_api_model.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';
import 'package:posfrontend/features/product/domain/entities/product_detail.dart';
import 'package:posfrontend/features/product/domain/entities/category.dart';
import 'package:posfrontend/features/product/domain/repositories/product_repository.dart';
import 'package:posfrontend/features/product/domain/repositories/product_detail_repository.dart';
import 'package:posfrontend/features/product/domain/repositories/product_manage_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;
  final Future<String?> Function() _currentShopId;

  ProductRepositoryImpl({
    ProductRemoteDataSource? remoteDataSource,
    ProductLocalDataSource? localDataSource,
    Future<String?> Function()? currentShopId,
  })  : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource(),
        _localDataSource = localDataSource ?? ProductLocalDataSource(),
        _currentShopId = currentShopId ?? SessionStore.currentShopId;

  @override
  Future<Map<String, dynamic>> getProducts({
    String? packageId,
    String? categoryId,
    String? search,
    String? sort,
    String? order,
    int page = 1,
    int perPage = 10,
    CancelToken? cancelToken,
  }) async {
    final shopId = await _currentShopId();
    if (shopId != null && shopId.isNotEmpty) {
      try {
        final cachedProducts = await _localDataSource.getCachedProducts(
          shopId: shopId,
          categoryId: categoryId,
          packageId: packageId,
          search: search,
          page: page,
          perPage: perPage,
        );
        if (cachedProducts.isNotEmpty) {
          return {
            'data': cachedProducts,
            'meta': {
              'current_page': page,
              'last_page': 1,
              'total': cachedProducts.length,
            },
          };
        }
      } catch (_) {
        // Ignore cache errors and fall back to network
      }
    }

    final response = await _remoteDataSource.getProducts(
      packageId: packageId,
      categoryId: categoryId,
      search: search,
      sort: sort,
      order: order,
      page: page,
      perPage: perPage,
      cancelToken: cancelToken,
    );

    // Cache the response for offline use
    if (shopId != null && shopId.isNotEmpty) {
      final data = response['data'];
      if (data is List) {
        final products = data
            .map((json) => ProductApiModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _localDataSource.cacheProducts(shopId: shopId, products: products);
      }
    }

    return response;
  }

  @override
  Future<ProductEntity?> getProductById(String productId) async {
    final shopId = await _currentShopId();
    if (shopId != null && shopId.isNotEmpty) {
      try {
        final cachedProduct = await _localDataSource.getCachedProductById(
          shopId: shopId,
          productId: productId,
        );
        if (cachedProduct != null) {
          return ProductEntity(
            id: cachedProduct.id,
            name: cachedProduct.name,
            brand: cachedProduct.brand,
            sku: cachedProduct.sku,
            price: cachedProduct.price,
            stock: cachedProduct.stock,
            isSet: cachedProduct.isSet,
            category: cachedProduct.category,
            imageUrl: cachedProduct.imageUrl,
          );
        }
      } catch (_) {
        // Ignore cache errors and fall back to network
      }
    }

    try {
      final model = await _remoteDataSource.getProductDetail(productId);
      return ProductEntity(
        id: model.id,
        name: model.name,
        brand: model.brand,
        sku: model.sku,
        price: model.price,
        stock: model.stockAvailable,
        isSet: model.isBundle,
        category: model.categoryName,
        imageUrl: model.imageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteProduct(String productId) {
    return _remoteDataSource.deleteProduct(productId);
  }
}

class ProductDetailRepositoryImpl implements ProductDetailRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final Future<String?> Function() _currentShopId;

  ProductDetailRepositoryImpl({
    ProductRemoteDataSource? remoteDataSource,
    Future<String?> Function()? currentShopId,
  })  : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource(),
        _currentShopId = currentShopId ?? SessionStore.currentShopId;

  @override
  Future<ProductDetailEntity> getDetail(
    String productId, {
    CancelToken? cancelToken,
  }) async {
    // Product detail is not cached locally - always fetch from network for fresh data
    final model = await _remoteDataSource.getProductDetail(
      productId,
      cancelToken: cancelToken,
    );
    return model.toEntity();
  }
}

class ProductManageRepositoryImpl implements ProductManageRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;
  final Future<String?> Function() _currentShopId;

  ProductManageRepositoryImpl({
    ProductRemoteDataSource? remoteDataSource,
    ProductLocalDataSource? localDataSource,
    Future<String?> Function()? currentShopId,
  })  : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource(),
        _localDataSource = localDataSource ?? ProductLocalDataSource(),
        _currentShopId = currentShopId ?? SessionStore.currentShopId;

  @override
  Future<List<Map<String, dynamic>>> getSuppliers() =>
      _remoteDataSource.getSuppliers();

  @override
  Future<List<Map<String, dynamic>>> getPackages() async {
    final shopId = await _currentShopId();
    if (shopId != null && shopId.isNotEmpty) {
      try {
        final cachedPackages = await _localDataSource.getCachedPackages(shopId: shopId);
        if (cachedPackages.isNotEmpty) {
          return cachedPackages;
        }
      } catch (_) {
        // Ignore cache errors and fall back to network
      }
    }

    final packages = await _remoteDataSource.getPackages();
    if (shopId != null && shopId.isNotEmpty) {
      await _localDataSource.cachePackages(shopId: shopId, packages: packages);
    }
    return packages;
  }

  @override
  Future<void> createProduct(Map<String, dynamic> data) =>
      _remoteDataSource.createProduct(data);

  @override
  Future<void> updateProduct(String productId, Map<String, dynamic> data) =>
      _remoteDataSource.updateProduct(productId, data);

  @override
  Future<List<ProductEntity>> searchProducts(String query) async {
    final models = await _remoteDataSource.searchProducts(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingPurchaseItems() =>
      _remoteDataSource.getPendingPurchaseItems();

  @override
  Future<void> completePurchaseItem(String itemId) =>
      _remoteDataSource.completePurchaseItem(itemId);
}

class CategoryRepositoryImpl implements CategoryRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;
  final Future<String?> Function() _currentShopId;

  CategoryRepositoryImpl({
    ProductRemoteDataSource? remoteDataSource,
    ProductLocalDataSource? localDataSource,
    Future<String?> Function()? currentShopId,
  })  : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource(),
        _localDataSource = localDataSource ?? ProductLocalDataSource(),
        _currentShopId = currentShopId ?? SessionStore.currentShopId;

  @override
  Future<List<Category>> getCategories() async {
    final shopId = await _currentShopId();
    if (shopId != null && shopId.isNotEmpty) {
      try {
        final cachedCategories = await _localDataSource.getCachedCategories(shopId: shopId);
        if (cachedCategories.isNotEmpty) {
          return cachedCategories.map((m) => m.toEntity()).toList();
        }
      } catch (_) {
        // Ignore cache errors and fall back to network
      }
    }

    final models = await _remoteDataSource.getCategories();
    if (shopId != null && shopId.isNotEmpty) {
      await _localDataSource.cacheCategories(shopId: shopId, categories: models);
    }
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> createCategory({
    required String name,
    String? description,
    String? inventoryId,
    String? type,
  }) {
    return _remoteDataSource.createCategory(
      name: name,
      description: description,
      inventoryId: inventoryId,
      type: type,
    );
  }

  @override
  Future<void> updateCategory(
    String id, {
    String? name,
    String? description,
    bool? active,
  }) {
    return _remoteDataSource.updateCategory(
      id,
      name: name,
      description: description,
      active: active,
    );
  }
}