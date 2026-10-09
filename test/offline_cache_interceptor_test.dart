import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posfrontend/core/local/app_database.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/core/network/connectivity.dart';
import 'package:posfrontend/core/network/offline_cache_interceptor.dart';

/// In-memory [LocalStore] so the interceptor tests never touch SQLite —
/// the point of these tests is the interceptor's routing decisions, not
/// the storage engine.
class FakeLocalStore extends LocalStore {
  final Map<String, String> bodies = {};
  List<({String url, DateTime storedAt})> urls;
  int writes = 0;
  int wipes = 0;
  DateTime? synced;

  FakeLocalStore({this.urls = const []});

  String _k(String cacheKey, String shopId) => '$shopId\n$cacheKey';

  @override
  Future<String?> cachedBody({
    required String cacheKey,
    required String shopId,
  }) async => bodies[_k(cacheKey, shopId)];

  @override
  Future<void> writeCachedBody({
    required String cacheKey,
    required String shopId,
    required String url,
    required String body,
  }) async {
    bodies[_k(cacheKey, shopId)] = body;
    writes++;
  }

  @override
  Future<List<({String url, DateTime storedAt})>> recentUrls({
    required String shopId,
    int limit = 20,
  }) async => urls.take(limit).toList();

  @override
  Future<DateTime?> lastSyncedAt({
    required String shopId,
    required String key,
  }) async => synced;

  @override
  Future<void> setLastSyncedAt({
    required String shopId,
    required String key,
    required DateTime at,
  }) async {
    synced = at;
  }

  @override
  Future<void> wipeAll() async {
    bodies.clear();
    wipes++;
  }

  final List<({String clientUuid, String kind, String payload, String shopId, String status, int attempts, String? resolvedServerId})> outbox = [];

  @override
  Future<void> outboxEnqueue({
    required String clientUuid,
    required String kind,
    required String payload,
    required String shopId,
  }) async {
    outbox.add((
      clientUuid: clientUuid,
      kind: kind,
      payload: payload,
      shopId: shopId,
      status: 'pending',
      attempts: 0,
      resolvedServerId: null,
    ));
  }

  @override
  Future<List<({
    String clientUuid,
    String kind,
    String payload,
    String? resolvedServerId,
  })>>
  outboxPending({required String shopId, int limit = 50}) async => outbox
      .where((e) => e.shopId == shopId && e.status == 'pending')
      .take(limit)
      .map(
        (e) => (
          clientUuid: e.clientUuid,
          kind: e.kind,
          payload: e.payload,
          resolvedServerId: e.resolvedServerId,
        ),
      )
      .toList();

  @override
  Future<void> outboxSetResolvedId({
    required String clientUuid,
    required String serverId,
  }) async {
    final i = outbox.indexWhere((e) => e.clientUuid == clientUuid);
    if (i == -1) return;
    final e = outbox[i];
    outbox[i] = (
      clientUuid: e.clientUuid,
      kind: e.kind,
      payload: e.payload,
      shopId: e.shopId,
      status: e.status,
      attempts: e.attempts,
      resolvedServerId: serverId,
    );
  }

  @override
  Future<void> outboxRecordAttempt({
    required String clientUuid,
    bool rejected = false,
    String? error,
  }) async {
    final i = outbox.indexWhere((e) => e.clientUuid == clientUuid);
    if (i == -1) return;
    final e = outbox[i];
    outbox[i] = (
      clientUuid: e.clientUuid,
      kind: e.kind,
      payload: e.payload,
      shopId: e.shopId,
      status: rejected ? 'failed' : e.status,
      attempts: e.attempts + 1,
      resolvedServerId: e.resolvedServerId,
    );
  }

  @override
  Future<void> outboxDelete({required String clientUuid}) async {
    outbox.removeWhere((e) => e.clientUuid == clientUuid);
  }

  @override
  Future<int> outboxCount({
    required String shopId,
    required String status,
  }) async =>
      outbox.where((e) => e.shopId == shopId && e.status == status).length;

  @override
  Future<void> close() async {}

  @override
  Future<AppDatabase> get database async => throw UnsupportedError('FakeLocalStore does not provide database');
}

/// Serves fixed responses, counts every network hit, and can simulate a
/// connection that never answers — a thrown [SocketException] is what dio
/// wraps into a response-less [DioException], exactly like a real outage.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter({
    this.networkDown = false,
    this.statusCode = 200,
    this.body = const {'data': []},
  });

  bool networkDown;
  int statusCode;
  Object? body;
  int fetches = 0;
  final List<String> requestedUrls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetches++;
    requestedUrls.add(options.uri.toString());
    if (networkDown) {
      throw const SocketException('network is down');
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const baseUrl = 'https://pos.test/api/v1';
  const shopId = 'shop-1';

  late FakeLocalStore store;
  late ConnectivityService connectivity;
  late FakeAdapter adapter;
  late Dio dio;

  /// Builds a dio with the interceptor under test as the only interceptor,
  /// so observed behaviour is attributable to it alone. Pass
  /// `shop: null` to simulate a session with no cached profile.
  Dio buildDio({String? shop = shopId}) {
    final d = Dio(BaseOptions(baseUrl: baseUrl));
    d.httpClientAdapter = adapter;
    d.interceptors.add(
      OfflineCacheInterceptor(
        store: store,
        connectivity: connectivity,
        currentShopId: () async => shop,
      ),
    );
    return d;
  }

  setUp(() {
    store = FakeLocalStore();
    connectivity = ConnectivityService();
    adapter = FakeAdapter();
    dio = buildDio();
  });

  group('write-through (online)', () {
    test('a successful allowlisted GET is cached under its absolute URI',
        () async {
      final response = await dio.get<dynamic>('/products');

      expect(response.statusCode, 200);
      expect(store.writes, 1);
      final key = 'GET $baseUrl/products';
      expect(store.bodies['$shopId\n$key'], isNotNull);
    });

    test('a 4xx response is not cached', () async {
      adapter.statusCode = 404;
      adapter.body = {'message': 'not found'};

      await expectLater(
        dio.get<dynamic>('/products'),
        throwsA(isA<DioException>()),
      );
      expect(store.writes, 0);
    });

    test('non-allowlisted endpoints are never cached', () async {
      await dio.get<dynamic>('/dashboard/summary');

      expect(store.writes, 0);
    });

    test('POST is never cached', () async {
      await dio.post<dynamic>('/products', data: {'name': 'x'});

      expect(store.writes, 0);
    });

    test('a response served from cache is not written back', () async {
      connectivity.debugSetOnline(false);
      store.bodies['$shopId\nGET $baseUrl/products'] =
          '{"data":[{"id":1}]}';

      await dio.get<dynamic>('/products');

      expect(store.writes, 0, reason: 'a cache hit must not re-write itself');
      expect(adapter.fetches, 0, reason: 'offline hits must not hit network');
    });
  });

  group('offline fast path', () {
    test('serves the cached body without touching the network', () async {
      connectivity.debugSetOnline(false);
      store.bodies['$shopId\nGET $baseUrl/products?page=1'] =
          '{"data":[{"id":7}],"meta":{"total":1}}';

      final response = await dio.get<dynamic>('/products?page=1');

      expect(response.statusCode, 200);
      expect(response.data['data'], [
        {'id': 7},
      ]);
      expect(adapter.fetches, 0);
    });

    test('offline with no cache still attempts the network', () async {
      connectivity.debugSetOnline(false);
      adapter.networkDown = true;

      await expectLater(
        dio.get<dynamic>('/products'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.fetches, 1,
          reason: 'a stale connectivity flag must not block a real request');
    });

    test('rows cached by another shop are not served', () async {
      connectivity.debugSetOnline(false);
      adapter.networkDown = true;
      store.bodies['other-shop\nGET $baseUrl/products'] = '{"data":[1,2,3]}';

      await expectLater(
        dio.get<dynamic>('/products'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.fetches, 1,
          reason: 'the foreign shop row must be a miss, not a serve');
    });

    test('a session with no shopId neither reads nor writes the cache',
        () async {
      final anonymous = buildDio(shop: null);
      connectivity.debugSetOnline(false);
      adapter.networkDown = true;
      store.bodies['$shopId\nGET $baseUrl/products'] = '{"data":[1]}';

      await expectLater(
        anonymous.get<dynamic>('/products'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.fetches, 1,
          reason: 'no session, no cache — the row must not be served');

      connectivity.debugSetOnline(true);
      adapter.networkDown = false;
      await anonymous.get<dynamic>('/categories');
      expect(store.writes, 0);
    });
  });

  group('failure fallback', () {
    test('a connection-level failure is answered from the cache', () async {
      store.bodies['$shopId\nGET $baseUrl/products'] = '{"data":[{"id":3}]}';
      adapter.networkDown = true;

      final response = await dio.get<dynamic>('/products');

      expect(response.statusCode, 200);
      expect(response.data['data'], [
        {'id': 3},
      ]);
    });

    test('a connection-level failure with no cache propagates', () async {
      adapter.networkDown = true;

      await expectLater(
        dio.get<dynamic>('/products'),
        throwsA(isA<DioException>()),
      );
    });

    test('a server error is never masked by the cache', () async {
      // The response arrived — the caller must see the real 500, not a
      // pleasantly stale 200.
      store.bodies['$shopId\nGET $baseUrl/products'] = '{"data":[]}';
      adapter.statusCode = 500;
      adapter.body = {'message': 'boom'};

      await expectLater(
        dio.get<dynamic>('/products'),
        throwsA(
          isA<DioException>()
              .having((e) => e.response?.statusCode, 'status', 500),
        ),
      );
    });
  });
}
