import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:posfrontend/core/network/api_client.dart';

/// What the network layer believes about connectivity, and the signal the
/// cache and sync manager react to.
///
/// ## Why this is not just `connectivity_plus`
///
/// The link layer answers "is there a network interface with a route", which
/// is not the same question as "can this app reach its server". A till on a
/// guest WiFi portal, a router that lost its uplink, or a VPN that dropped
/// all report a connected interface while every API call times out. Trusting
/// the link layer alone would let the app decide it is online and then hang
/// for the full 20-second [ApiClient] connect timeout on every request.
///
/// So there are two stages: the interface says *maybe*, then a probe against
/// the server origin says *yes*. Only the probe result is published.
///
/// ## Probe semantics
///
/// Any HTTP answer counts as reachable — a 404 or a redirect still proves
/// the server answered. A captive portal therefore reads as online; that is
/// accepted, because the failure mode is benign: the real request fails and
/// the cache interceptor falls back to the cached body anyway.
///
/// [isOnline] starts optimistically `true`. Until the first probe says
/// otherwise the app must behave exactly as it did before this feature
/// existed, and a wrong `false` would serve stale data to a perfectly
/// healthy connection.
///
/// ## Why a failed probe is retried
///
/// A single probe is a single sample of a moving target: at launch the
/// backend may still be booting, DNS may not have settled, or the network
/// interface may have come up a moment before its route did. Publishing that
/// sample as a permanent answer is what made the app say "Offline" on an
/// online device — `connectivity_plus` only reports link *changes*, so a link
/// that never changes would never trigger a re-probe for the rest of the
/// session. A failed probe therefore arms a retry on [_retryDelays], which
/// backs off while the server stays unreachable and stops the moment it
/// answers. Link loss cancels it: there is nothing to reach until the link
/// returns.
class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    Dio? probe,
    String? baseUrl,
    List<Duration>? retryDelays,
  }) : _connectivity = connectivity ?? Connectivity(),
       _probe = probe,
       _baseUrlOverride = baseUrl,
       _retryDelays = (retryDelays == null || retryDelays.isEmpty)
           ? defaultRetryDelays
           : List.unmodifiable(retryDelays);

  /// Re-probe cadence after a failed answer: the last entry is the ceiling,
  /// held for as long as the server stays unreachable rather than given up
  /// on, because "unreachable right now" is never a permanent property.
  static const defaultRetryDelays = <Duration>[
    Duration(seconds: 3),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  final Connectivity _connectivity;
  final Dio? _probe;

  /// Compile-time `BASE_URL` unless a test supplies its own origin.
  final String? _baseUrlOverride;
  final List<Duration> _retryDelays;

  /// Whether the API server is believed reachable. Read by the cache
  /// interceptor (serve-from-cache fast path) and the sync manager.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _started = false;
  bool _probing = false;

  /// Set when a link event arrives while a probe is in flight. The answer
  /// that lands may predate the event, so it is not to be trusted alone; the
  /// flag makes the probe run once more instead of dropping the event.
  bool _probeQueued = false;

  /// The last known state of the link layer. Retries are pointless without
  /// one, and link loss must cancel them.
  bool _hasLink = false;

  int _probeGeneration = 0;
  int _retryAttempt = 0;
  Timer? _retryTimer;

  static ConnectivityService? _instance;

  /// Process-wide instance. See `LocalStore.instance` for why the core
  /// statics in this app do not go through `get_it`.
  static ConnectivityService get instance =>
      _instance ??= ConnectivityService();

  @visibleForTesting
  static set instanceForTesting(ConnectivityService? service) =>
      _instance = service;

  /// Begins listening. Safe to call more than once; later calls are no-ops.
  ///
  /// A no-op on web: there is no offline mode there (the local store is out
  /// of scope for the web build, and the browser already owns connectivity),
  /// so the app must never publish `false` and hang the "Offline" pill over
  /// an online page. [isOnline] stays at its optimistic `true` for the whole
  /// session.
  Future<void> start() async {
    if (kIsWeb) return;
    if (_started) return;
    _started = true;

    _subscription = _connectivity.onConnectivityChanged.listen(_onLinkChanged);
    _onLinkChanged(await _connectivity.checkConnectivity());
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _cancelRetry();
    _started = false;
  }

  void _onLinkChanged(List<ConnectivityResult> results) {
    final hasLink =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    _hasLink = hasLink;
    // A new link event is a new situation: the backoff ladder starts over so
    // a network change is judged on its own evidence, not on how many times
    // the previous one failed.
    _retryAttempt = 0;
    if (!hasLink) {
      // No interface at all: nothing to probe, and the answer is immediate.
      // Bumping the generation cancels any probe still in flight so a stale
      // "yes" cannot overwrite this "no".
      _probeGeneration++;
      _probeQueued = false;
      _cancelRetry();
      _setOnline(false);
      return;
    }
    _probeServer();
  }

  Future<void> _probeServer() async {
    if (_probing) {
      _probeQueued = true;
      return;
    }
    _probing = true;
    final generation = ++_probeGeneration;
    try {
      final reachable = await _reachServer();
      // A stale answer — the link changed underneath us — is discarded
      // entirely: the event that invalidated it already published its own
      // state, and arming a retry from a result nobody accepted would
      // fight it.
      if (generation == _probeGeneration) {
        _setOnline(reachable);
        if (reachable) {
          _retryAttempt = 0;
          _cancelRetry();
        } else {
          _scheduleRetry();
        }
      }
    } finally {
      _probing = false;
      if (_probeQueued) {
        _probeQueued = false;
        // Only if a link is still present: link loss clears the flag, and
        // its own answer is already the published one.
        if (_hasLink) unawaited(_probeServer());
      }
    }
  }

  /// Arms the next probe after a failure, walking [_retryDelays] up to its
  /// ceiling and then holding it.
  void _scheduleRetry() {
    if (!_hasLink || _retryTimer != null) return;
    final last = _retryDelays.length - 1;
    final index = _retryAttempt < last ? _retryAttempt : last;
    _retryAttempt++;
    _retryTimer = Timer(_retryDelays[index], () {
      _retryTimer = null;
      if (_hasLink) _probeServer();
    });
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<bool> _reachServer() async {
    final base = _baseUrlOverride ?? ApiClient.baseUrl;
    if (base.isEmpty) {
      // No origin configured to probe (unset BASE_URL during development):
      // fall back to believing the link layer rather than declaring every
      // session offline.
      return true;
    }
    try {
      final dio = _probe ??
          Dio(
            BaseOptions(
              baseUrl: base,
              connectTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 3),
              // Any answer — including 404, 302 or 500 — proves reachability.
              validateStatus: (_) => true,
              headers: const {'Accept': 'application/json'},
            ),
          );
      await dio.get<dynamic>('/api');
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  void _setOnline(bool value) {
    if (isOnline.value != value) isOnline.value = value;
  }

  /// Test seam: feeds a link-layer result through the same path the
  /// subscription uses, without a real `connectivity_plus` listener.
  @visibleForTesting
  void debugLinkChanged(List<ConnectivityResult> results) =>
      _onLinkChanged(results);

  /// Test seam: forces the published state without a probe.
  @visibleForTesting
  void debugSetOnline(bool value) => _setOnline(value);
}
