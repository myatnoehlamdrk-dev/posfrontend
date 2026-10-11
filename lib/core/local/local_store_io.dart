import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:posfrontend/core/local/app_database.dart';
import 'package:posfrontend/core/local/local_store.dart';

/// Creates the SQLite-backed store. Imported only on `dart.library.io`
/// platforms; the web build takes `local_store_web.dart` instead.
LocalStore createPlatformStore() => DriftLocalStore();

/// SQLite-backed [LocalStore] for every native platform the app ships on.
///
/// The file lives in the application support directory rather than a
/// documents directory because the cache is regenerable state: it must not
/// show up in a user's file browser, an iTunes/Android file share, or a
/// document backup. A till that gets its cache wiped by an OS cleanup loses
/// nothing that a reconnect cannot rebuild.
class DriftLocalStore extends LocalStore {
  DriftLocalStore({AppDatabase? database}) : _db = database;

  AppDatabase? _db;

  Future<AppDatabase> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'offline_cache.sqlite'));
    return _db = AppDatabase(NativeDatabase.createInBackground(file));
  }

  @override
  Future<String?> cachedBody({
    required String cacheKey,
    required String shopId,
  }) async {
    final db = await _database;
    final row = await (db.select(db.cachedHttpResponses)
          ..where((t) => t.cacheKey.equals(cacheKey) & t.shopId.equals(shopId)))
        .getSingleOrNull();
    return row?.body;
  }

  @override
  Future<void> writeCachedBody({
    required String cacheKey,
    required String shopId,
    required String url,
    required String body,
  }) async {
    final db = await _database;
    await db.into(db.cachedHttpResponses).insertOnConflictUpdate(
      CachedHttpResponsesCompanion.insert(
        cacheKey: cacheKey,
        shopId: shopId,
        url: url,
        body: body,
        storedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<({String url, DateTime storedAt})>> recentUrls({
    required String shopId,
    int limit = 20,
  }) async {
    final db = await _database;
    final rows =
        await (db.select(db.cachedHttpResponses)
              ..where((t) => t.shopId.equals(shopId))
              ..orderBy([(t) => OrderingTerm.desc(t.storedAt)])
              ..limit(limit))
            .get();
    return rows.map((r) => (url: r.url, storedAt: r.storedAt)).toList();
  }

  @override
  Future<DateTime?> lastSyncedAt({
    required String shopId,
    required String key,
  }) async {
    final db = await _database;
    final row = await (db.select(db.syncMeta)
          ..where((t) => t.shopId.equals(shopId) & t.key.equals(key)))
        .getSingleOrNull();
    return row?.lastSyncedAt;
  }

  @override
  Future<void> setLastSyncedAt({
    required String shopId,
    required String key,
    required DateTime at,
  }) async {
    final db = await _database;
    await db.into(db.syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion.insert(
        shopId: shopId,
        key: key,
        lastSyncedAt: at,
      ),
    );
  }

  @override
  Future<void> wipeAll() async {
    final db = await _database;
    await db.delete(db.cachedHttpResponses).go();
    await db.delete(db.syncMeta).go();
    // Outbox entries are intentionally left alone: an unsent sale is money
    // already taken at the till, and it stays queued for its own shop's
    // session to flush. See `OutboxEntries`.
  }

  @override
  Future<void> outboxEnqueue({
    required String clientUuid,
    required String kind,
    required String payload,
    required String shopId,
  }) async {
    final db = await _database;
    await db
        .into(db.outboxEntries)
        .insert(
          OutboxEntriesCompanion.insert(
            clientUuid: clientUuid,
            kind: kind,
            payload: payload,
            shopId: shopId,
            status: 'pending',
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<
    List<({
      String clientUuid,
      String kind,
      String payload,
      String? resolvedServerId,
    })>
  >
  outboxPending({required String shopId, int limit = 50}) async {
    final db = await _database;
    final rows =
        await (db.select(db.outboxEntries)
              ..where(
                (t) => t.shopId.equals(shopId) & t.status.equals('pending'),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(limit))
            .get();
    return rows
        .map(
          (r) => (
            clientUuid: r.clientUuid,
            kind: r.kind,
            payload: r.payload,
            resolvedServerId: r.resolvedServerId,
          ),
        )
        .toList();
  }

  @override
  Future<void> outboxSetResolvedId({
    required String clientUuid,
    required String serverId,
  }) async {
    final db = await _database;
    await (db.update(db.outboxEntries)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .write(OutboxEntriesCompanion(resolvedServerId: Value(serverId)));
  }

  @override
  Future<void> outboxRecordAttempt({
    required String clientUuid,
    bool rejected = false,
    String? error,
  }) async {
    final db = await _database;
    final row =
        await (db.select(db.outboxEntries)
              ..where((t) => t.clientUuid.equals(clientUuid)))
            .getSingleOrNull();
    if (row == null) return;

    await (db.update(db.outboxEntries)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .write(
      OutboxEntriesCompanion(
        attempts: Value(row.attempts + 1),
        lastAttemptAt: Value(DateTime.now()),
        status: rejected ? const Value('failed') : const Value.absent(),
        lastError: Value(error ?? (rejected ? row.lastError : null)),
      ),
    );
  }

  @override
  Future<void> outboxDelete({required String clientUuid}) async {
    final db = await _database;
    await (db.delete(db.outboxEntries)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .go();
  }

  @override
  Future<int> outboxCount({
    required String shopId,
    required String status,
  }) async {
    final db = await _database;
    final count = db.outboxEntries.id.count();
    final query = db.selectOnly(db.outboxEntries)
      ..addColumns([count])
      ..where(
        db.outboxEntries.shopId.equals(shopId) &
            db.outboxEntries.status.equals(status),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }

  @override
  Future<AppDatabase> get database async => _database;
}
