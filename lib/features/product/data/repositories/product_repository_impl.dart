import 'package:posfrontend/features/product/data/datasources/product_remote_data_source.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';
import 'package:posfrontend/features/product/domain/entities/product_detail.dart';
import 'package:posfrontend/features/product/domain/entities/category.dart';
import 'package:posfrontend/features/product/domain/repositories/product_repository.dart';
import 'package:posfrontend/features/product/domain/repositories/product_detail_repository.dart';
import 'package:posfrontend/features/product/domain/repositories/product_manage_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl({ProductRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource();

  @override
  Future<List<ProductEntity>> getProducts({String? packageId}) async {
    final models = await _remoteDataSource.getProducts(packageId: packageId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ProductEntity?> getProductById(String productId) async {
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

  ProductDetailRepositoryImpl({ProductRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource();

  @override
  Future<ProductDetailEntity> getDetail(String productId) async {
    final model = await _remoteDataSource.getProductDetail(productId);
    return model.toEntity();
  }
}

class ProductManageRepositoryImpl implements ProductManageRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductManageRepositoryImpl({ProductRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource();

  @override
  Future<List<Map<String, dynamic>>> getSuppliers() => _remoteDataSource.getSuppliers();

  @override
  Future<List<Map<String, dynamic>>> getPackages() => _remoteDataSource.getPackages();

  @override
  Future<void> createProduct(Map<String, dynamic> data) => _remoteDataSource.createProduct(data);

  @override
  Future<void> updateProduct(String productId, Map<String, dynamic> data) => _remoteDataSource.updateProduct(productId, data);

  @override
  Future<List<ProductEntity>> searchProducts(String query) async {
    final models = await _remoteDataSource.searchProducts(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingPurchaseItems() => _remoteDataSource.getPendingPurchaseItems();

  @override
  Future<void> completePurchaseItem(String itemId) => _remoteDataSource.completePurchaseItem(itemId);
}

class CategoryRepositoryImpl implements CategoryRepository {
  final ProductRemoteDataSource _remoteDataSource;

  CategoryRepositoryImpl({ProductRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource();

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final models = await _remoteDataSource.getCategories();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> createCategory({required String name, String? description, String? inventoryId, String? type}) {
    return _remoteDataSource.createCategory(name: name, description: description, inventoryId: inventoryId, type: type);
  }

  @override
  Future<void> updateCategory(String id, {String? name, String? description, bool? active}) {
    return _remoteDataSource.updateCategory(id, name: name, description: description, active: active);
  }
}
