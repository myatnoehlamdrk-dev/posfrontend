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
}
