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
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity, Dio? probe})
    : _connectivity = connectivity ?? Connectivity(),
      _probe = probe;

  final Connectivity _connectivity;
  final Dio? _probe;

  /// Whether the API server is believed reachable. Read by the cache
  /// interceptor (serve-from-cache fast path) and the sync manager.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _started = false;
  bool _probing = false;
  int _probeGeneration = 0;

  static ConnectivityService? _instance;

  /// Process-wide instance. See `LocalStore.instance` for why the core
  /// statics in this app do not go through `get_it`.
  static ConnectivityService get instance =>
      _instance ??= ConnectivityService();

  @visibleForTesting
  static set instanceForTesting(ConnectivityService? service) =>
      _instance = service;

  /// Begins listening. Safe to call more than once; later calls are no-ops.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _subscription = _connectivity.onConnectivityChanged.listen(_onLinkChanged);
    _onLinkChanged(await _connectivity.checkConnectivity());
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }

  void _onLinkChanged(List<ConnectivityResult> results) {
    final hasLink =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (!hasLink) {
      // No interface at all: nothing to probe, and the answer is immediate.
      // Bumping the generation cancels any probe still in flight so a stale
      // "yes" cannot overwrite this "no".
      _probeGeneration++;
      _setOnline(false);
      return;
    }
    _probeServer();
  }

  Future<void> _probeServer() async {
    if (_probing) return;
    _probing = true;
    final generation = ++_probeGeneration;
    try {
      final reachable = await _reachServer();
      if (generation == _probeGeneration) _setOnline(reachable);
    } finally {
      _probing = false;
    }
  }

  Future<bool> _reachServer() async {
    final base = ApiClient.baseUrl;
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

  /// Test seam: forces the published state without a probe.
  @visibleForTesting
  void debugSetOnline(bool value) => _setOnline(value);
}
