import 'package:dio/dio.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/category/data/datasources/category_remote_data_source.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _dataSource;

  CategoryRepositoryImpl({CategoryRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? CategoryRemoteDataSource();

  @override
  Future<List<Category>> getCategories({
    String? type,
    String? inventoryId,
  }) async {
    try {
      final models = await _dataSource.getCategories(
        type: type,
        inventoryId: inventoryId,
      );
      return models.map((m) => m.toEntity()).toList();
    } on ApiException {
      rethrow;
    }
  }

  @override
  Future<PaginatedResponse<Category>> getCategoriesPage({
    String? type,
    String? inventoryId,
    int page = 1,
    int perPage = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final result = await _dataSource.getCategoriesPage(
        type: type,
        inventoryId: inventoryId,
        page: page,
        perPage: perPage,
        cancelToken: cancelToken,
      );
      return PaginatedResponse(
        data: result.data.map((m) => m.toEntity()).toList(),
        lastPage: result.lastPage,
        currentPage: result.currentPage,
        total: result.total,
      );
    } on ApiException {
      rethrow;
    }
  }

  @override
  Future<Category> getCategoryById(
    String id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final model = await _dataSource.getCategoryById(
        id,
        cancelToken: cancelToken,
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    }
  }

  @override
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
  }) async {
    try {
      final model = await _dataSource.createCategory(
        type: type,
        name: name,
        description: description,
        packageLimit: packageLimit,
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    }
  }

  @override
  Future<Category> updateCategory({
    required String id,
    required String name,
    String? description,
    int? packageLimit,
  }) async {
    try {
      final model = await _dataSource.updateCategory(
        id: id,
        name: name,
        description: description,
        packageLimit: packageLimit,
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) {
    return _dataSource.deleteCategory(id);
  }
}
