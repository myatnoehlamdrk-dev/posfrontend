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

    // Network-first, not cache-first. OfflineCacheInterceptor documents the
    // app's contract as "network-first, always: cached data only ever speaks
    // when the network cannot", and it already answers an offline GET from
    // the byte-for-byte response body. Serving these Drift rows first broke
    // that: the `categories` table has no productImages, createdDate,
    // createdBy or imageUrl column, so once it had a row every later load
    // returned a round-tripped subset and the categories screen lost its
    // three-image mosaic, its "Created:" line and its author.
    List<CategoryApiModel> models;
    try {
      models = await _remoteDataSource.getCategories(
        type: type,
        inventoryId: inventoryId,
      );
    } catch (_) {
      // Reachable only when the network and the response cache both came up
      // empty (a first launch with no link, say). Still worth serving the
      // rows we have rather than nothing.
      final cached = await _cachedCategories(shopId, type, inventoryId);
      if (cached.isNotEmpty) {
        return cached.map((m) => m.toEntity()).toList();
      }
      rethrow;
    }

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

    // Same network-first order as [getCategories] -- see the note there. The
    // cache-first version also invented the paginator's answers from one
    // page of local rows (`lastPage: 1`, `total: cached.length`), so a
    // category list longer than a page stopped paging the moment the cache
    // was used.
    PaginatedResponse<CategoryApiModel> result;
    try {
      result = await _remoteDataSource.getCategoriesPage(
        type: type,
        inventoryId: inventoryId,
        page: page,
        perPage: perPage,
        cancelToken: cancelToken,
      );
    } catch (_) {
      final cached = await _cachedCategories(
        shopId,
        type,
        inventoryId,
        page: page,
        perPage: perPage,
      );
      if (cached.isNotEmpty) {
        return PaginatedResponse(
          data: cached.map((m) => m.toEntity()).toList(),
          lastPage: 1,
          currentPage: page,
          total: cached.length,
        );
      }
      rethrow;
    }

    if (shopId != null && shopId.isNotEmpty) {
      await _localDataSource.cacheCategories(
        shopId: shopId,
        categories: result.data,
      );
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
    try {
      final model = await _remoteDataSource.getCategoryById(
        id,
        cancelToken: cancelToken,
      );
      return model.toEntity();
    } catch (_) {
      final cached = await _cachedCategories(shopId, null, null);
      final hit = cached.where((c) => c.id == id).firstOrNull;
      if (hit != null) return hit.toEntity();
      rethrow;
    }
  }

  /// The Drift rows for a shop, or an empty list if there are none or the
  /// read fails.
  ///
  /// Deliberately a *last resort*. The response cache held by
  /// [OfflineCacheInterceptor] is the offline mirror: it stores the whole
  /// response body, so an offline read comes back byte-for-byte as the
  /// server sent it, images and all. These rows cannot do that — the table
  /// is a fixed set of columns written by [cacheCategories] — so they are
  /// only consulted when the network and that cache have both failed.
  Future<List<CategoryApiModel>> _cachedCategories(
    String? shopId,
    String? type,
    String? inventoryId, {
    int page = 1,
    int perPage = 20,
  }) async {
    if (shopId == null || shopId.isEmpty) return const [];
    try {
      return await _localDataSource.getCachedCategories(
        shopId: shopId,
        type: type,
        inventoryId: inventoryId,
        page: page,
        perPage: perPage,
      );
    } catch (_) {
      return const [];
    }
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