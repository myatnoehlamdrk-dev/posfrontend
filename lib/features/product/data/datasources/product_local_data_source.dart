import 'package:drift/drift.dart';
import 'package:posfrontend/core/local/app_database.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/features/product/data/models/product_api_model.dart';
import 'package:posfrontend/features/product/data/models/category_api_model.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';
import 'package:posfrontend/features/product/domain/entities/category.dart';

class ProductLocalDataSource {
  final LocalStore _store;

  ProductLocalDataSource({LocalStore? store}) : _store = store ?? LocalStore.instance;

  Future<AppDatabase> get _db async => _store.database;

  Future<void> cacheProducts({
    required String shopId,
    required List<ProductApiModel> products,
  }) async {
    final db = await _db;
    await db.batch((batch) {
      for (final product in products) {
        batch.insert(
          db.products,
          ProductsCompanion.insert(
            id: product.id,
            shopId: shopId,
            name: product.name,
            brand: Value(product.brand),
            sku: Value(product.sku),
            price: product.price,
            stock: product.stock,
            isSet: Value(product.isSet),
            categoryId: Value(product.category),
            packageId: Value(product.packageId),
            imageUrl: Value(product.imageUrl),
            createdBy: Value(product.createdBy),
            updatedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
        for (final variant in product.variants) {
          batch.insert(
            db.productVariants,
            ProductVariantsCompanion.insert(
              productId: product.id,
              shopId: shopId,
              size: variant.size,
              color: variant.color,
              quantity: variant.quantity,
              price: variant.price,
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

  Future<List<ProductApiModel>> getCachedProducts({
    required String shopId,
    String? categoryId,
    String? packageId,
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    final db = await _db;
    final query = db.select(db.products)..where((p) => p.shopId.equals(shopId));

    if (categoryId != null && categoryId.isNotEmpty) {
      query.where((p) => p.categoryId.equals(categoryId));
    }
    if (packageId != null && packageId.isNotEmpty) {
      query.where((p) => p.packageId.equals(packageId));
    }
    if (search != null && search.isNotEmpty) {
      query.where((p) => p.name.like('%$search%') | p.sku.like('%$search%'));
    }

    query
      ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
      ..limit(perPage, offset: (page - 1) * perPage);

    final rows = await query.get();
    final result = <ProductApiModel>[];
    for (final row in rows) {
      final variants = await (db.select(db.productVariants)
            ..where((v) => v.productId.equals(row.id) & v.shopId.equals(shopId)))
          .get();
      result.add(ProductApiModel(
        id: row.id,
        name: row.name,
        brand: row.brand ?? '',
        sku: row.sku ?? '',
        price: row.price,
        stock: row.stock,
        isSet: row.isSet,
        category: row.categoryId ?? '',
        packageId: row.packageId ?? '',
        imageUrl: row.imageUrl,
        variants: variants.map((v) => ProductVariantApiModel(
          size: v.size,
          color: v.color,
          quantity: v.quantity,
          price: v.price,
        )).toList(),
        createdBy: row.createdBy ?? '',
      ));
    }
    return result;
  }

  Future<ProductApiModel?> getCachedProductById({
    required String shopId,
    required String productId,
  }) async {
    final db = await _db;
    final row = await (db.select(db.products)
          ..where((p) => p.id.equals(productId) & p.shopId.equals(shopId)))
        .getSingleOrNull();
    if (row == null) return null;

    final variants = await (db.select(db.productVariants)
          ..where((v) => v.productId.equals(productId) & v.shopId.equals(shopId)))
        .get();

    return ProductApiModel(
      id: row.id,
      name: row.name,
      brand: row.brand ?? '',
      sku: row.sku ?? '',
      price: row.price,
      stock: row.stock,
      isSet: row.isSet,
      category: row.categoryId ?? '',
      packageId: row.packageId ?? '',
      imageUrl: row.imageUrl,
      variants: variants.map((v) => ProductVariantApiModel(
        size: v.size,
        color: v.color,
        quantity: v.quantity,
        price: v.price,
      )).toList(),
      createdBy: row.createdBy ?? '',
    );
  }

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
  }) async {
    final db = await _db;
    final query = db.select(db.categories)..where((c) => c.shopId.equals(shopId));

    if (type != null && type.isNotEmpty) {
      query.where((c) => c.type.equals(type));
    }
    if (inventoryId != null && inventoryId.isNotEmpty) {
      query.where((c) => c.inventoryId.equals(inventoryId));
    }

    query.orderBy([(c) => OrderingTerm.desc(c.updatedAt)]);

    final rows = await query.get();
    return rows.map((row) => CategoryApiModel(
      id: row.id,
      name: row.name,
      inventoryId: row.inventoryId,
      type: row.type,
      packageCount: row.packageCount,
      packageLimit: row.packageLimit,
      description: row.description,
      active: row.active,
    )).toList();
  }

  Future<void> cachePackages({
    required String shopId,
    required List<Map<String, dynamic>> packages,
  }) async {
    final db = await _db;
    await db.batch((batch) {
      for (final pkg in packages) {
        batch.insert(
          db.packages,
          PackagesCompanion.insert(
            id: pkg['id']?.toString() ?? '',
            shopId: shopId,
            name: pkg['name']?.toString() ?? '',
            description: Value(pkg['description']?.toString()),
            price: (pkg['price'] as num?)?.toDouble() ?? 0.0,
            categoryId: Value(pkg['categoryId']?.toString()),
            updatedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getCachedPackages({
    required String shopId,
  }) async {
    final db = await _db;
    final rows = await (db.select(db.packages)
          ..where((p) => p.shopId.equals(shopId))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .get();
    return rows.map((row) => {
      'id': row.id,
      'name': row.name,
      'description': row.description,
      'price': row.price,
      'categoryId': row.categoryId,
    }).toList();
  }

  Future<void> clearShopCache(String shopId) async {
    final db = await _db;
    await (db.delete(db.products)..where((p) => p.shopId.equals(shopId))).go();
    await (db.delete(db.categories)..where((c) => c.shopId.equals(shopId))).go();
    await (db.delete(db.packages)..where((p) => p.shopId.equals(shopId))).go();
    await (db.delete(db.productVariants)..where((v) => v.shopId.equals(shopId))).go();
  }
}