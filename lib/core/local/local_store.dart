import 'package:flutter/foundation.dart';
import 'package:posfrontend/core/local/app_database.dart';
import 'package:posfrontend/core/local/local_store_web.dart'
    if (dart.library.io) 'package:posfrontend/core/local/local_store_io.dart'
    as platform;

/// Process-wide access to the offline cache.
///
/// ## Why this is a static singleton and not `get_it`
///
/// The three callers that must reach it — `SessionStore` (wipe on account
/// switch), `TokenStorage`'s logout paths, and the Dio cache interceptor —
/// are themselves static utilities with no constructor injection. Routing
/// them through `get_it` would mean every one of them importing the DI graph
/// just to delete a table. The singleton is created lazily on first use and
/// is replaceable in tests through [instanceForTesting].
///
/// ## Platform split
///
/// Offline support is a native-only feature: Android, iOS, Windows, macOS,
/// Linux. The web build is online-only by decision, so it gets
/// [NoopLocalStore] through the conditional import below — every call site
/// compiles and runs on every platform, and the web build pays nothing.
abstract class LocalStore {
  LocalStore();

  static LocalStore? _instance;

  /// The store for this platform. Falls back to a no-op implementation where
  /// Drift cannot run (the web build).
  static LocalStore get instance => _instance ??= platform.createPlatformStore();

  /// Resets the singleton instance. Useful for hot restart to recreate the database connection.
  static void reset() {
    _instance?.close();
    _instance = null;
  }

  /// Replaces the process-wide store. Passing null restores the platform
  /// default on next access. Tests use this to install a fake.
  @visibleForTesting
  static set instanceForTesting(LocalStore? store) => _instance = store;

  /// The cached body for [cacheKey], or null on a miss.
  ///
  /// [shopId] is part of the lookup: a row cached by one shop's session is a
  /// miss for every other shop, even if the table has not been wiped yet.
  Future<String?> cachedBody({
    required String cacheKey,
    required String shopId,
  });

  /// Stores the body of a successful response.
  Future<void> writeCachedBody({
    required String cacheKey,
    required String shopId,
    required String url,
    required String body,
  });

  /// The most recently cached request URLs for [shopId], newest first.
  ///
  /// The sync manager replays these to warm the cache. [limit] keeps a long
  /// history of one-off searches from turning a reconnect into an
  /// unbounded burst of requests.
  Future<List<({String url, DateTime storedAt})>> recentUrls({
    required String shopId,
    int limit = 20,
  });

  Future<DateTime?> lastSyncedAt({
    required String shopId,
    required String key,
  });

  Future<void> setLastSyncedAt({
    required String shopId,
    required String key,
    required DateTime at,
  });

  /// Deletes the *read* cache — cached responses and sync metadata.
  ///
  /// Called on logout and whenever a login brings in a different shop: the
  /// cache belongs to a session, not to a device.
  ///
  /// The outbox is deliberately **not** cleared here. An unsent sale is
  /// money the till has already taken; see [OutboxEntries] for how it stays
  /// scoped to its shop instead.
  Future<void> wipeAll();

  // -- Outbox (queued writes) ---------------------------------------------

  /// Adds a queued write. [payload] is the exact JSON body the original
  /// request would have carried.
  Future<void> outboxEnqueue({
    required String clientUuid,
    required String kind,
    required String payload,
    required String shopId,
  });

  /// Queued writes for [shopId] in enqueueing order, oldest first.
  Future<
    List<({
      String clientUuid,
      String kind,
      String payload,
      String? resolvedServerId,
    })>
  >
  outboxPending({required String shopId, int limit = 50});

  /// Captures the server id returned by the first half of a compound entry
  /// so the retry after a mid-pair outage skips the half that already ran.
  Future<void> outboxSetResolvedId({
    required String clientUuid,
    required String serverId,
  });

  /// Records a delivery attempt: bumps `attempts`, stamps `lastAttemptAt`,
  /// and — when [rejected] — parks the entry as `failed` with [error] so it
  /// stops being retried until a human looks at it.
  ///
  /// A connection-level failure passes `rejected: false` with a null error:
  /// the entry stays `pending` for the next flush.
  Future<void> outboxRecordAttempt({
    required String clientUuid,
    bool rejected = false,
    String? error,
  });

  Future<void> outboxDelete({required String clientUuid});

  /// Number of entries with [status] (`pending`/`failed`) for [shopId].
  Future<int> outboxCount({required String shopId, required String status});

  Future<void> close();

  /// Returns the underlying Drift database for direct queries.
  /// Only available on native platforms with Drift support.
  Future<AppDatabase> get database;
}

/// The web build's store: offline support is explicitly out of scope there,
/// so reads always miss and writes are discarded. Repositories therefore
/// behave exactly as they did before this feature existed.
class NoopLocalStore extends LocalStore {
  @override
  Future<String?> cachedBody({
    required String cacheKey,
    required String shopId,
  }) async => null;

  @override
  Future<void> writeCachedBody({
    required String cacheKey,
    required String shopId,
    required String url,
    required String body,
  }) async {}

  @override
  Future<List<({String url, DateTime storedAt})>> recentUrls({
    required String shopId,
    int limit = 20,
  }) async =>
      const [];

  @override
  Future<DateTime?> lastSyncedAt({
    required String shopId,
    required String key,
  }) async =>
      null;

  @override
  Future<void> setLastSyncedAt({
    required String shopId,
    required String key,
    required DateTime at,
  }) async {}

  @override
  Future<void> wipeAll() async {}

  @override
  Future<void> outboxEnqueue({
    required String clientUuid,
    required String kind,
    required String payload,
    required String shopId,
  }) async {
    // Throwing rather than dropping: a silently discarded sale is lost
    // revenue the cashier believes was recorded. With no local database to
    // hold it, the honest behaviour is to fail the write so the original
    // network error surfaces to the caller.
    throw UnsupportedError(
      'Offline writes are not available on this platform.',
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
  outboxPending({required String shopId, int limit = 50}) async => const [];

  @override
  Future<void> outboxSetResolvedId({
    required String clientUuid,
    required String serverId,
  }) async {}

  @override
  Future<void> outboxRecordAttempt({
    required String clientUuid,
    bool rejected = false,
    String? error,
  }) async {}

  @override
  Future<void> outboxDelete({required String clientUuid}) async {}

  @override
  Future<int> outboxCount({
    required String shopId,
    required String status,
  }) async =>
      0;

  @override
  Future<void> close() async {}

  @override
  Future<AppDatabase> get database async =>
      throw UnsupportedError('No local database on web platform');
}
