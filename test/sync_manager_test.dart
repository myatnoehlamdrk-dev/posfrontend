import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posfrontend/core/local/sync_manager.dart';
import 'package:posfrontend/core/network/connectivity.dart';

import 'offline_cache_interceptor_test.dart' show FakeAdapter, FakeLocalStore;

void main() {
  const shopId = 'shop-1';

  late FakeLocalStore store;
  late ConnectivityService connectivity;
  late FakeAdapter adapter;
  late Dio dio;
  late SyncManager sync;

  setUp(() {
    store = FakeLocalStore();
    connectivity = ConnectivityService();
    connectivity.debugSetOnline(true);
    adapter = FakeAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://pos.test/api/v1'));
    dio.httpClientAdapter = adapter;
    sync = SyncManager(
      dio: dio,
      store: store,
      connectivity: connectivity,
      currentShopId: () async => shopId,
      interval: const Duration(minutes: 5),
    );
  });

  tearDown(() => sync.stop());

  test('replays the cached URLs and records the sync time', () async {
    store.urls = [
      (url: 'https://pos.test/api/v1/products', storedAt: DateTime.now()),
      (
        url: 'https://pos.test/api/v1/categories/with-products',
        storedAt: DateTime.now(),
      ),
    ];

    await sync.syncNow();

    expect(adapter.fetches, 2);
    expect(store.synced, isNotNull);
    expect(sync.lastSyncedAt.value, store.synced);
    expect(sync.state.value, SyncState.idle);
  });

  test('an empty cache is a no-op, not a failure', () async {
    await sync.syncNow();

    expect(adapter.fetches, 0);
    expect(sync.state.value, SyncState.idle);
    expect(sync.lastSyncedAt.value, isNull);
  });

  test('does nothing while offline', () async {
    store.urls = [(url: 'https://pos.test/api/v1/products', storedAt: DateTime.now())];
    connectivity.debugSetOnline(false);

    await sync.syncNow();

    expect(adapter.fetches, 0);
    expect(sync.state.value, SyncState.idle);
  });

  test('a failed refresh is reported as failed, not idle', () async {
    store.urls = [(url: 'https://pos.test/api/v1/products', storedAt: DateTime.now())];
    adapter.networkDown = true;

    await sync.syncNow();

    expect(sync.state.value, SyncState.failed);
    expect(store.synced, isNull, reason: 'a failed run must not advance time');
  });

  test('concurrent triggers collapse into a single run', () async {
    store.urls = [(url: 'https://pos.test/api/v1/products', storedAt: DateTime.now())];

    await Future.wait([sync.syncNow(), sync.syncNow(), sync.syncNow()]);

    expect(adapter.fetches, 1);
  });

  test('a partial success still counts as synced', () async {
    store.urls = [
      (url: 'https://pos.test/api/v1/products', storedAt: DateTime.now()),
      (url: 'https://pos.test/api/v1/packages', storedAt: DateTime.now()),
    ];
    // First request succeeds, second never answers.
    dio.httpClientAdapter = _SelectiveAdapter(failAfter: 1);

    await sync.syncNow();

    expect(sync.state.value, SyncState.idle);
    expect(store.synced, isNotNull);
  });
}

/// Serves the first [failAfter] requests and then simulates an outage, so
/// a mixed run (some cached URLs succeed, some do not) can be observed.
class _SelectiveAdapter implements HttpClientAdapter {
  _SelectiveAdapter({required this.failAfter});

  final int failAfter;
  int _seen = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_seen++ >= failAfter) throw const SocketException('down');
    return ResponseBody.fromString(
      '{"data":[]}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
