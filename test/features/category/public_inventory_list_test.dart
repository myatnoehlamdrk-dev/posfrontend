import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/features/category/data/datasources/category_local_data_source.dart';
import 'package:posfrontend/features/category/data/datasources/category_remote_data_source.dart';
import 'package:posfrontend/features/category/data/models/category_api_model.dart';
import 'package:posfrontend/features/category/data/repositories/category_repository_impl.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';
import 'package:posfrontend/features/category/presentation/viewmodels/category_view_model.dart';
import 'package:posfrontend/features/inventory/domain/entities/inventory.dart';
import 'package:posfrontend/features/inventory/domain/repositories/inventory_repository.dart';

class _FakeRemote extends CategoryRemoteDataSource {
  _FakeRemote(this._page)
    // A dio that is never used. The default constructor builds the real
    // ApiClient, whose baseUrl comes from `String.fromEnvironment('BASE_URL')`
    // and so is empty outside a `--dart-define` build.
    : super(dio: Dio(BaseOptions(baseUrl: 'http://localhost/api/v1')));

  final PaginatedResponse<CategoryApiModel> _page;

  @override
  Future<PaginatedResponse<CategoryApiModel>> getCategoriesPage({
    String? type,
    String? inventoryId,
    int page = 1,
    int perPage = 20,
    CancelToken? cancelToken,
  }) async =>
      _page;
}

/// The repository the web build actually gets: [NoopLocalStore] answers every
/// read with a miss and, for `database`, throws.
CategoryLocalDataSource _webLocalDataSource() =>
    CategoryLocalDataSource(store: NoopLocalStore());

PaginatedResponse<CategoryApiModel> _onePage() => PaginatedResponse(
  data: [
    CategoryApiModel(
      id: '450001',
      name: 'Home',
      inventoryId: '60002',
      type: 'public',
    ),
  ],
  lastPage: 1,
  currentPage: 1,
  total: 1,
);

void main() {
  group('CategoryRepositoryImpl.getCategoriesPage', () {
    // Reproduces the public inventory screen on web: the network answers, the
    // offline cache write then throws because the browser build has no local
    // database, and the freshly fetched page was being thrown away with it.
    test('a failed offline-cache write keeps the fetched page', () async {
      final repository = CategoryRepositoryImpl(
        remoteDataSource: _FakeRemote(_onePage()),
        localDataSource: _webLocalDataSource(),
        currentShopId: () async => '10090001',
      );

      final result = await repository.getCategoriesPage(
        type: 'public',
        page: 1,
        perPage: 5,
      );

      expect(result.data, hasLength(1));
      expect(result.data.single.name, 'Home');
      expect(result.total, 1);
    });

    test('a shop with no session still returns the fetched page', () async {
      final repository = CategoryRepositoryImpl(
        remoteDataSource: _FakeRemote(_onePage()),
        localDataSource: _webLocalDataSource(),
        currentShopId: () async => null,
      );

      final result = await repository.getCategoriesPage(type: 'public');

      expect(result.data, hasLength(1));
    });
  });

  group('CategoryViewModel.load', () {
    // The screen renders "No categories found." only when `hasError` is false,
    // so a failure the view model does not recognise has to become an error
    // rather than escape and leave a blank list behind.
    test('surfaces a failure it does not recognise instead of blanking', () async {
      final viewModel = CategoryViewModel(
        repository: _FailingCategoryRepository(),
        inventoryRepository: _FakeInventoryRepository(),
        type: 'public',
      );

      await viewModel.load();

      expect(viewModel.hasError, isTrue);
      expect(viewModel.errorMessage, isNotEmpty);
      expect(viewModel.isLoading, isFalse);
    });

    test('keeps the fetched list when the load succeeds', () async {
      final viewModel = CategoryViewModel(
        repository: _SucceedingCategoryRepository(),
        inventoryRepository: _FakeInventoryRepository(),
        type: 'public',
      );

      await viewModel.load();

      expect(viewModel.hasError, isFalse);
      expect(viewModel.filtered, hasLength(1));
    });
  });
}

class _FakeInventoryRepository implements InventoryRepository {
  @override
  List<InventoryOptionEntity> getOptions() => const [];

  @override
  Future<InventoryEntity> getInventoryByType(String type) async =>
      const InventoryEntity(id: '60002', shopId: '10090001', type: 'public');
}

/// Throws something that is neither an [AppException] nor a [DioException],
/// the way an unexpected parse or platform error would.
class _FailingCategoryRepository implements CategoryRepository {
  @override
  Future<PaginatedResponse<Category>> getCategoriesPage({
    String? type,
    String? inventoryId,
    int page = 1,
    int perPage = 20,
    CancelToken? cancelToken,
  }) async =>
      throw UnsupportedError('no local database on web platform');

  @override
  Future<List<Category>> getCategories({String? type, String? inventoryId}) async =>
      throw UnsupportedError('no local database on web platform');

  @override
  Future<Category> getCategoryById(String id, {CancelToken? cancelToken}) async =>
      throw UnimplementedError();

  @override
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Category> updateCategory({
    required String id,
    required String name,
    String? description,
    int? packageLimit,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) async => throw UnimplementedError();
}

class _SucceedingCategoryRepository implements CategoryRepository {
  @override
  Future<PaginatedResponse<Category>> getCategoriesPage({
    String? type,
    String? inventoryId,
    int page = 1,
    int perPage = 20,
    CancelToken? cancelToken,
  }) async => PaginatedResponse(
    data: const [Category(id: '450001', name: 'Home', type: 'public')],
    lastPage: 1,
    currentPage: 1,
    total: 1,
  );

  @override
  Future<List<Category>> getCategories({String? type, String? inventoryId}) async =>
      const [Category(id: '450001', name: 'Home', type: 'public')];

  @override
  Future<Category> getCategoryById(String id, {CancelToken? cancelToken}) async =>
      throw UnimplementedError();

  @override
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Category> updateCategory({
    required String id,
    required String name,
    String? description,
    int? packageLimit,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) async => throw UnimplementedError();
}
