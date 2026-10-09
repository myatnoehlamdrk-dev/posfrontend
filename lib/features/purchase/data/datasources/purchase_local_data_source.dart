import 'package:drift/drift.dart';
import 'package:posfrontend/core/local/app_database.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/features/purchase/data/models/purchase_api_model.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';

class PurchaseLocalDataSource {
  final LocalStore _store;

  PurchaseLocalDataSource({LocalStore? store}) : _store = store ?? LocalStore.instance;

  Future<AppDatabase> get _db async => _store.database;

  Future<void> cachePurchaseItems({
    required String shopId,
    required List<PurchaseOrderApiModel> items,
  }) async {
    final db = await _db;
    await db.batch((batch) {
      for (final item in items) {
        batch.insert(
          db.purchaseItems,
          PurchaseItemsCompanion.insert(
            id: item.orderId,
            shopId: shopId,
            productName: item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            date: item.date,
            supplierId: Value(item.supplierId),
            notes: Value(item.notes),
            size: const Value.absent(),
            color: const Value.absent(),
            brand: const Value.absent(),
            sku: const Value.absent(),
            status: item.status.name,
            updatedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<PurchaseOrderApiModel>> getCachedPurchaseItems({
    required String shopId,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final db = await _db;
    final query = db.select(db.purchaseItems)..where((p) => p.shopId.equals(shopId));

    if (status != null && status.isNotEmpty) {
      query.where((p) => p.status.equals(status));
    }

    query
      ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
      ..limit(perPage, offset: (page - 1) * perPage);

    final rows = await query.get();
    return rows.map((row) => PurchaseOrderApiModel(
      orderId: row.id,
      supplierId: row.supplierId ?? '',
      supplierName: '',
      productName: row.productName,
      quantity: row.quantity,
      unitPrice: row.unitPrice,
      date: row.date,
      status: row.status == 'completed' ? PurchaseStatus.completed : PurchaseStatus.pending,
      notes: row.notes ?? '',
      createdBy: '',
      updatedBy: '',
      createdAt: '',
      updatedAt: row.updatedAt.toIso8601String(),
    )).toList();
  }

  Future<void> clearShopCache(String shopId) async {
    final db = await _db;
    await (db.delete(db.purchaseItems)..where((p) => p.shopId.equals(shopId))).go();
  }
}