import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/core/network/connectivity.dart';

/// A Dio interceptor that turns the local database into an offline mirror
/// of selected GET endpoints.
///
/// ## The shape of the cache: responses, not entities
///
/// The catalog screen, the category view model and a handful of screens
/// call Dio directly instead of going through a repository, so wiring a
/// cache into repositories alone would miss exactly the screens that matter
/// most offline. Caching the *response body* — keyed by the absolute URI —
/// covers every call site at once, with no changes to any of them, and
/// guarantees an offline read is byte-for-byte what the server returned.
///
/// ## Three paths, in order of priority
///
/// 1. **Known offline + cache hit** — serve the cached body immediately in
///    `onRequest`. The request never reaches the network, so there is no
///    timeout to wait out: this is the path that makes an offline catalog
///    open instantly.
/// 2. **Online** — pass through to the server. On success the body is
///    written through to the cache. Network-first, always: cached data only
///    ever speaks when the network cannot.
/// 3. **Network-level failure + cache hit** — in `onError`, a request that
///    never got a response (DNS failure, connection refused, timeout) is
///    answered from the cache. A response that *did* arrive — a 4xx or 5xx
///    — is never masked: the server said something, and the caller needs to
///    hear it.
///
/// This interceptor is registered **first** on purpose. In dio 5 the whole
/// interceptor chain runs in registration order, including error handlers,
/// so being first means: a cache hit skips the auth token read and the
/// logger, and a cache fallback short-circuits `RetryInterceptor` — retrying
/// a request that has already been answered from the cache would be wasted
/// backoff on a till with no internet.
///
/// ## Scope
///
/// Reads only. `POST`/`PATCH`/`DELETE` are never cached and never served
/// from cache; offline *writes* are the outbox queue's job, not this
/// interceptor's. The cacheable roots are an allowlist because a cached
/// body for the wrong endpoint is a bug that shows up as a very confusing
/// empty screen.
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor({
    LocalStore? store,
    ConnectivityService? connectivity,
    Future<String?> Function()? currentShopId,
  }) : _storeOverride = store,
       _connectivityOverride = connectivity,
       _currentShopId = currentShopId ?? SessionStore.currentShopId;

  final LocalStore? _storeOverride;
  final ConnectivityService? _connectivityOverride;
  final Future<String?> Function() _currentShopId;

  /// URL roots whose GET responses may be cached. Deliberately narrow —
  /// the catalog is what a cashier needs to sell while offline; dashboards
  /// and reports can wait for the reconnect.
  static const Set<String> _cacheableRoots = {
    'products',
    'categories',
    'packages',
  };

  /// Set on a request when its response came from the cache, so the write
  /// path does not immediately re-write the body it just read.
  static const String _cacheHitKey = 'offline_cache_hit';

  LocalStore get _store => _storeOverride ?? LocalStore.instance;
  ConnectivityService get _connectivity =>
      _connectivityOverride ?? ConnectivityService.instance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_eligible(options)) return handler.next(options);

    final shopId = await _shopId();
    if (shopId == null || shopId.isEmpty) return handler.next(options);

    // Fast path: known offline, answer instantly from the database. When
    // offline but there is no cached copy, fall through and let the network
    // attempt fail on its own — the error path will report it properly, and
    // the connectivity state may simply be stale.
    if (!_connectivity.isOnline.value) {
      final body = await _store.cachedBody(
        cacheKey: _key(options),
        shopId: shopId,
      );
      if (body != null) {
        options.extra[_cacheHitKey] = true;
        handler.resolve(_fabricate(options, body));
        return;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (response.statusCode != 200 || !_eligible(options)) {
      return handler.next(response);
    }
    // A response we just served from the cache is already in the cache.
    if (options.extra[_cacheHitKey] == true) return handler.next(response);

    final data = response.data;
    if (data == null) return handler.next(response);

    final shopId = await _shopId();
    if (shopId == null || shopId.isEmpty) return handler.next(response);

    final String body;
    if (data is String) {
      body = data;
    } else {
      try {
        body = jsonEncode(data);
      } catch (_) {
        // A body that cannot be re-encoded cannot be served back in the
        // same shape later; skipping it loses nothing but offline support
        // for that one endpoint.
        return handler.next(response);
      }
    }

    await _store.writeCachedBody(
      cacheKey: _key(options),
      shopId: shopId,
      url: options.uri.toString(),
      body: body,
    );
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    // A response that arrived is a real answer (404, 500, ...) — surfacing
    // it is the whole point of the caller's error handling. Only *absence*
    // of a response qualifies for the cache.
    if (err.response != null || !_eligible(options)) {
      return handler.next(err);
    }

    final shopId = await _shopId();
    if (shopId == null || shopId.isEmpty) return handler.next(err);

    final body = await _store.cachedBody(
      cacheKey: _key(options),
      shopId: shopId,
    );
    if (body == null) return handler.next(err);

    options.extra[_cacheHitKey] = true;
    handler.resolve(_fabricate(options, body));
  }

  /// True for the requests this interceptor manages: an allowlisted GET
  /// that has not opted out through `extra['no_cache']`.
  bool _eligible(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return false;
    if (options.extra['no_cache'] == true) return false;

    // Works for both shapes the call sites use: a relative path handed to
    // Dio (`/products`) and an absolute URI (`https://host/api/v1/products`).
    // Taking the first three segments covers the `api/v1/...` prefix
    // without hard-coding the version.
    final segments = options.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .take(3);
    return segments.any(_cacheableRoots.contains);
  }

  /// The cache key: method plus absolute URI (query included).
  ///
  /// Built from [RequestOptions.uri] rather than the path as written,
  /// because the sync manager re-issues stored URLs through `getUri` and
  /// the key must come out identical for the write to land on the row the
  /// read used.
  String _key(RequestOptions options) => 'GET ${options.uri}';

  Future<String?> _shopId() => _currentShopId();

  /// Rebuilds a response from a cached body so dio treats it as the answer.
  ///
  /// Resolved (not passed along) deliberately: a served-from-cache response
  /// is not evidence that the session works, so `AuthInterceptor.onResponse`
  /// — which takes any success as proof the token is alive — must not run.
  Response<dynamic> _fabricate(RequestOptions options, String body) {
    dynamic data;
    try {
      data = jsonDecode(body);
    } catch (_) {
      // Not JSON after all — hand it back exactly as stored.
      data = body;
    }
    return Response<dynamic>(
      requestOptions: options,
      statusCode: 200,
      data: data,
      headers: Headers.fromMap({
        'content-type': ['application/json'],
      }),
    );
  }
}
