import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/network/connectivity.dart';
import 'package:posfrontend/core/offline/offline_writes_flag.dart';
import 'package:posfrontend/core/offline/outbox_queue.dart';

/// What the sync layer is currently doing, for the status banner.
enum SyncState {
  /// Nothing in flight. Online with a fresh cache, or offline with the
  /// cache serving reads.
  idle,

  /// A background refresh is running.
  syncing,

  /// The last refresh attempt could not reach the server while the app
  /// believed it was online. Retried on the next trigger.
  failed,
}

/// Keeps the offline cache warm by re-issuing the requests the app has
/// already made, whenever the app comes back to the foreground or the
/// network comes back.
///
/// ## Why replay stored URLs rather than fetch "the catalog"
///
/// The cache is a mirror of actual call sites — the catalog's
/// `/categories/with-products?productLimit=20`, a cashier's search, a
/// package listing with its `categoryId`. Re-issuing exactly those URIs
/// means the refresh warms the rows the screens will read, with the same
/// query shapes the screens use, and the cache interceptor writes each
/// response back under the same key the read side looks up. Inventing a
/// "canonical" set of endpoints instead would risk warming URLs no screen
/// ever requests while missing the ones they do.
///
/// A first launch with an empty cache therefore has nothing to replay —
/// which is correct: there is no stale data to refresh, and the screens
/// populate the cache as they are used.
///
/// ## Triggers
///
/// - connectivity flips offline → online (the reconnect moment),
/// - the app returns to the foreground (a till can sit on a screen for
///   hours; resume is when staleness is discovered),
/// - a periodic timer as a backstop for a session that never leaves the
///   foreground and never loses link state,
/// - and an immediate pass at startup, so a launch on fresh internet does
///   not show yesterday's cache for longer than one round trip.
///
/// Single-flight by design: overlapping triggers collapse into the run
/// that is already in progress. A POS spends most of its life on one
/// screen, and a periodic timer plus a flapping link can otherwise stack
/// request bursts on a small device.
class SyncManager {
  SyncManager({
    Dio? dio,
    LocalStore? store,
    ConnectivityService? connectivity,
    Future<String?> Function()? currentShopId,
    this.interval = const Duration(minutes: 5),
    this.maxUrlsPerRun = 20,
  }) : _dio = dio ?? ApiClient.instance,
       _store = store ?? LocalStore.instance,
       _connectivity = connectivity ?? ConnectivityService.instance,
       _currentShopId = currentShopId ?? SessionStore.currentShopId;

  final Dio _dio;
  final LocalStore _store;
  final ConnectivityService _connectivity;
  final Future<String?> Function() _currentShopId;
  final Duration interval;
  final int maxUrlsPerRun;

  /// Publishes state for the banner. Never holds `syncing` across an
  /// await the caller can observe after the run ended — see [syncNow].
  final ValueNotifier<SyncState> state = ValueNotifier<SyncState>(SyncState.idle);

  /// When the catalog was last confirmed fresh, for "saved data, 10:32".
  /// Null until the first successful run under the current session.
  final ValueNotifier<DateTime?> lastSyncedAt = ValueNotifier<DateTime?>(null);

  /// Meta key written under [SyncManager.lastSyncedAt]'s storage.
  static const String _metaKey = 'catalog';

  Timer? _timer;
  bool _started = false;
  bool _running = false;
  bool _wasOnline = true;
  AppLifecycleListener? _lifecycle;

  static SyncManager? _instance;

  /// Process-wide instance; see `LocalStore.instance` on the static
  /// singleton style used by this app's core services.
  static SyncManager get instance => _instance ??= SyncManager();

  @visibleForTesting
  static set instanceForTesting(SyncManager? manager) => _instance = manager;

  /// Resets the singleton instance. Useful for hot restart.
  static void reset() {
    _instance?.stop();
    _instance = null;
  }

  /// Registers every trigger. Safe to call repeatedly; only the first call
  /// has an effect, so it can be called from app startup without guarding.
  void start() {
    if (_started) return;
    _started = true;

    _wasOnline = _connectivity.isOnline.value;
    _connectivity.isOnline.addListener(_onConnectivityChanged);

    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) syncNow();
      },
    );

    _timer = Timer.periodic(interval, (_) => syncNow());

    // A launch that is already online should not display cache older than
    // one round trip, if there is a cache at all.
    syncNow();
  }

  Future<void> stop() async {
    _connectivity.isOnline.removeListener(_onConnectivityChanged);
    _lifecycle?.dispose();
    _lifecycle = null;
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  void _onConnectivityChanged() {
    final online = _connectivity.isOnline.value;
    final cameBackOnline = online && !_wasOnline;
    _wasOnline = online;
    if (cameBackOnline) syncNow();
  }

  /// Refreshes every URL the app has cached under the current shop.
  ///
  /// No-op when offline, when a run is already in flight, or when no shop
  /// is signed in — all three are normal states, not errors.
  Future<void> syncNow() async {
    if (_running || !_connectivity.isOnline.value) return;

    // Acquired synchronously, before the first await: three triggers
    // arriving in the same microtask (a reconnect firing the timer, the
    // lifecycle listener and the link listener together) must still count
    // as one run.
    _running = true;
    state.value = SyncState.syncing;
    try {
      final shopId = await _currentShopId();
      if (shopId == null || shopId.isEmpty) {
        state.value = SyncState.idle;
        return;
      }

      // Flush queued writes before warming the cache: a sale made offline
      // changes stock, so the catalog refresh that runs after the flush
      // will pick up the corrected numbers rather than the pre-flush ones.
      if (OfflineWrites.enabled) {
        await OutboxQueue.instance.flush();
      }

      final cached = await _store.recentUrls(
        shopId: shopId,
        limit: maxUrlsPerRun,
      );
      if (cached.isEmpty) {
        // Nothing cached yet: first run, or a fresh account. Screens fill
        // the cache as they are used, so there is nothing to warm — and
        // "nothing to do" must not leave the banner spinning.
        state.value = SyncState.idle;
        return;
      }

      // Parallel on purpose: one round trip of wall-clock time instead of
      // N, and a server that is down fails every request together rather
      // than serially. Write-through happens in the interceptor.
      final results = await Future.wait(
        cached.map((entry) async {
          try {
            return await _dio.getUri<dynamic>(Uri.parse(entry.url));
          } catch (_) {
            return null;
          }
        }),
      );
      final successes = results.whereType<Response<dynamic>>().length;

      if (successes > 0) {
        final now = DateTime.now();
        await _store.setLastSyncedAt(shopId: shopId, key: _metaKey, at: now);
        lastSyncedAt.value = now;
        state.value = SyncState.idle;
      } else {
        state.value = SyncState.failed;
      }
    } catch (_) {
      // A refresh failure must never surface as an app error: the cache is
      // a convenience, and the screens already handle their own network
      // errors. The state notifier is the only channel this gets reported
      // through.
      state.value = SyncState.failed;
    } finally {
      _running = false;
    }
  }

  /// Loads the persisted timestamp for the current session, so the banner
  /// can show a real "saved data, 10:32" after a cold start rather than
  /// forgetting when the last sync happened.
  Future<void> loadPersistedSyncTime() async {
    final shopId = await _currentShopId();
    if (shopId == null || shopId.isEmpty) return;
    lastSyncedAt.value = await _store.lastSyncedAt(
      shopId: shopId,
      key: _metaKey,
    );
  }
}
