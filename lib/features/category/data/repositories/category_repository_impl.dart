import 'package:dio/dio.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/features/category/data/datasources/category_local_data_source.dart';
import 'package:posfrontend/features/category/data/datasources/category_remote_data_source.dart';
import 'package:posfrontend/features/category/data/models/category_api_model.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remoteDataSource;
  final CategoryLocalDataSource _localDataSource;
  final Future<String?> Function() _currentShopId;

  CategoryRepositoryImpl({
    CategoryRemoteDataSource? remoteDataSource,
    CategoryLocalDataSource? localDataSource,
    Future<String?> Function()? currentShopId,
  })  : _remoteDataSource = remoteDataSource ?? CategoryRemoteDataSource(),
        _localDataSource = localDataSource ?? CategoryLocalDataSource(),
        _currentShopId = currentShopId ?? SessionStore.currentShopId;

  @override
  Future<List<Category>> getCategories({
    String? type,
    String? inventoryId,
  }) async {
    final shopId = await _currentShopId();
    if (shopId != null && shopId.isNotEmpty) {
      try {
        final cachedCategories = await _localDataSource.getCachedCategories(
          shopId: shopId,
          type: type,
          inventoryId: inventoryId,
        );
        if (cachedCategories.isNotEmpty) {
          return cachedCategories.map((m) => m.toEntity()).toList();
        }
      } catch (_) {
        // Ignore cache errors and fall back to network
      }
    }

    final models = await _remoteDataSource.getCategories(
      type: type,
      inventoryId: inventoryId,
    );

    if (shopId != null && shopId.isNotEmpty) {
      await _localDataSource.cacheCategories(shopId: shopId, categories: models);
    }

    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<PaginatedResponse<Category>> getCategoriesPage({
    String? type,
    String? inventoryId,
    int page = 1,
    int perPage = 20,
    CancelToken? cancelToken,
  }) async {
    final shopId = await _currentShopId();
    if (shopId != null && shopId.isNotEmpty) {
      try {
        final cachedCategories = await _localDataSource.getCachedCategories(
          shopId: shopId,
          type: type,
          inventoryId: inventoryId,
          page: page,
          perPage: perPage,
        );
        if (cachedCategories.isNotEmpty) {
          return PaginatedResponse(
            data: cachedCategories.map((m) => m.toEntity()).toList(),
            lastPage: 1,
            currentPage: page,
            total: cachedCategories.length,
          );
        }
      } catch (_) {
        // Ignore cache errors and fall back to network
      }
    }

    final result = await _remoteDataSource.getCategoriesPage(
      type: type,
      inventoryId: inventoryId,
      page: page,
      perPage: perPage,
      cancelToken: cancelToken,
    );

    if (shopId != null && shopId.isNotEmpty) {
      await _localDataSource.cacheCategories(shopId: shopId, categories: result.data);
    }

    return PaginatedResponse(
      data: result.data.map((m) => m.toEntity()).toList(),
      lastPage: result.lastPage,
      currentPage: result.currentPage,
      total: result.total,
    );
  }

  @override
  Future<Category> getCategoryById(
    String id, {
    CancelToken? cancelToken,
  }) async {
    final shopId = await _currentShopId();
    if (shopId != null && shopId.isNotEmpty) {
      try {
        final cachedCategories = await _localDataSource.getCachedCategories(
          shopId: shopId,
        );
        final cachedCategory = cachedCategories
            .where((c) => c.id == id)
            .firstOrNull;
        if (cachedCategory != null) {
          return cachedCategory.toEntity();
        }
      } catch (_) {
        // Ignore cache errors and fall back to network
      }
    }

    final model = await _remoteDataSource.getCategoryById(
      id,
      cancelToken: cancelToken,
    );
    return model.toEntity();
  }

  @override
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
  }) async {
    final model = await _remoteDataSource.createCategory(
      type: type,
      name: name,
      description: description,
      packageLimit: packageLimit,
    );
    return model.toEntity();
  }

  @override
  Future<Category> updateCategory({
    required String id,
    required String name,
    String? description,
    int? packageLimit,
  }) async {
    final model = await _remoteDataSource.updateCategory(
      id: id,
      name: name,
      description: description,
      packageLimit: packageLimit,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteCategory(String id) {
    return _remoteDataSource.deleteCategory(id);
  }
}