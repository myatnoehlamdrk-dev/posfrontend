import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// A product cached for offline access.
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get sku => text().nullable()();
  RealColumn get price => real()();
  IntColumn get stock => integer()();
  BoolColumn get isSet => boolean().withDefault(const Constant(false))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get packageId => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id, shopId};
}

/// A category cached for offline access.
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text()();
  TextColumn get inventoryId => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get packageCount => integer().nullable()();
  IntColumn get packageLimit => integer().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id, shopId};
}

/// A package cached for offline access.
class Packages extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  TextColumn get categoryId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id, shopId};
}

/// A purchase item cached for offline access.
class PurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  IntColumn get unitPrice => integer()();
  TextColumn get date => text()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get size => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id, shopId};
}

/// A product variant cached for offline access.
class ProductVariants extends Table {
  TextColumn get productId => text()();
  TextColumn get shopId => text()();
  TextColumn get size => text()();
  TextColumn get color => text()();
  IntColumn get quantity => integer()();
  RealColumn get price => real()();

  @override
  Set<Column> get primaryKey => {productId, shopId, size, color};
}

/// One row per cached GET response body.
///
/// The cache is a *mirror of what the server last said*, not a model of the
/// domain: caching the exact body keeps every existing parse path — including
/// the screens that call Dio directly instead of going through a repository —
/// working offline without a single call-site change.
///
/// [cacheKey] is the absolute request URI (with query). [shopId] is on every
/// row because a device can change accounts: reads are always filtered by the
/// current session's shop, and a login under a different shop wipes the table
/// outright (see `SessionStore`). A row written for shop A must never be
/// served to shop B, which is what the composite primary key enforces.
class CachedHttpResponses extends Table {
  TextColumn get cacheKey => text()();

  TextColumn get shopId => text()();

  /// Absolute URI the body came from, kept for the sync manager to re-issue.
  TextColumn get url => text()();

  /// The response body exactly as received (JSON re-encoded to a string).
  TextColumn get body => text()();

  DateTimeColumn get storedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey, shopId};
}

/// When each class of data was last refreshed from the server.
///
/// Drives the "saved data, 10:32" part of the offline banner: the banner has
/// to be able to say *how old* the data on screen is rather than pretend it
/// is current.
class SyncMeta extends Table {
  TextColumn get shopId => text()();

  /// What was synced, e.g. `catalog`.
  TextColumn get key => text()();

  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {shopId, key};
}

/// A write the app accepted from the cashier but has not yet delivered to
/// the server — the outbox.
///
/// ## Why this survives the session wipe
///
/// `LocalStore.wipeAll` empties the *read* cache on logout and on an
/// account switch, because cached catalog rows belong to a session. These
/// rows are different in kind: an unsent sale is money the till has already
/// taken. Deleting it because somebody logged out would silently lose a
/// sale. So the outbox is excluded from the wipe, and [shopId] becomes the
/// scoping mechanism instead — a flush only ever posts entries recorded
/// under the session that is currently signed in, so shop B's token can
/// never send shop A's sales, and shop A's sales wait until shop A's
/// session returns.
///
/// ## Client UUID
///
/// The idempotency key the backend does not read *yet*. Until the server
/// de-duplicates on it, a flush after an ambiguous failure (the request
/// reached the server but the response was lost) can duplicate — which is
/// exactly why this table is behind the [OfflineWrites] flag. Once the
/// backend grows a unique index on this column, the same value makes the
/// queue safe to flush blindly.
class OutboxEntries extends Table {
  /// Server order of enqueueing; flush walks the queue FIFO. Drift makes
  /// `autoIncrement()` the primary key on its own — declaring both is a
  /// compile-time warning, not a stronger guarantee.
  IntColumn get id => integer().autoIncrement()();

  /// Client-generated UUID, sent as `Idempotency-Key`.
  TextColumn get clientUuid => text()();

  /// What kind of request this replays, e.g. `sale`, `order-items`, or the
  /// compound `sale-from-draft`.
  TextColumn get kind => text()();

  /// The exact JSON body the original call would have sent. For the
  /// compound `sale-from-draft` this is a wrapper holding both the draft
  /// order body and the sale body.
  TextColumn get payload => text()();

  /// Server-side id captured from the first half of a compound entry.
  ///
  /// A `sale-from-draft` entry has to POST the draft order, learn the
  /// server's order id, then POST the sale referencing it. If the network
  /// dies between the two calls the entry stays `pending` — and retrying
  /// blindly would create a *second* draft order. Writing the id here as
  /// soon as the first POST succeeds makes the pair restart-safe: the next
  /// flush skips straight to the sale half.
  TextColumn get resolvedServerId => text().nullable()();

  TextColumn get shopId => text()();

  /// `pending` is retried on every flush; `failed` means the server
  /// answered with a rejection (validation, insufficient stock) and
  /// retrying without a human decision would just fail again.
  TextColumn get status => text()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}

@DriftDatabase(tables: [
  CachedHttpResponses,
  SyncMeta,
  OutboxEntries,
  Products,
  Categories,
  Packages,
  PurchaseItems,
  ProductVariants,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(outboxEntries);
      if (from < 3) {
        // Idempotent: try to add column, ignore if already exists
        try {
          await m.addColumn(outboxEntries, outboxEntries.resolvedServerId);
        } catch (_) {
          // Column already exists, continue
        }
      }
      if (from < 4) {
        await m.createTable(products);
        await m.createTable(categories);
        await m.createTable(packages);
        await m.createTable(purchaseItems);
        await m.createTable(productVariants);
      }
    },
  );
}
