import 'package:drift/drift.dart';
import 'package:posfrontend/core/local/app_database.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/features/category/data/models/category_api_model.dart';

class CategoryLocalDataSource {
  final LocalStore _store;

  CategoryLocalDataSource({LocalStore? store}) : _store = store ?? LocalStore.instance;

  Future<AppDatabase> get _db async => _store.database;

  Future<void> cacheCategories({
    required String shopId,
    required List<CategoryApiModel> categories,
  }) async {
    final db = await _db;
    await db.batch((batch) {
      for (final category in categories) {
        batch.insert(
          db.categories,
          CategoriesCompanion.insert(
            id: category.id,
            shopId: shopId,
            name: category.name,
            inventoryId: Value(category.inventoryId),
            type: Value(category.type),
            description: Value(category.description),
            packageCount: Value(category.packageCount),
            packageLimit: Value(category.packageLimit),
            active: Value(category.active),
            updatedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<CategoryApiModel>> getCachedCategories({
    required String shopId,
    String? type,
    String? inventoryId,
    int page = 1,
    int perPage = 20,
  }) async {
    final db = await _db;
    final query = db.select(db.categories)..where((c) => c.shopId.equals(shopId));

    if (type != null && type.isNotEmpty) {
      query.where((c) => c.type.equals(type));
    }
    if (inventoryId != null && inventoryId.isNotEmpty) {
      query.where((c) => c.inventoryId.equals(inventoryId));
    }

    query
      ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)])
      ..limit(perPage, offset: (page - 1) * perPage);

    final rows = await query.get();
    return rows.map((row) => CategoryApiModel(
      id: row.id,
      name: row.name,
      inventoryId: row.inventoryId ?? '',
      type: row.type ?? '',
      packageCount: row.packageCount ?? 0,
      packageLimit: row.packageLimit ?? 0,
      description: row.description ?? '',
      active: row.active,
    )).toList();
  }

  Future<void> clearShopCache(String shopId) async {
    final db = await _db;
    await (db.delete(db.categories)..where((c) => c.shopId.equals(shopId))).go();
  }
}