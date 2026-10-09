import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posfrontend/core/offline/offline_writes_flag.dart';
import 'package:posfrontend/core/offline/outbox_queue.dart';

import 'offline_cache_interceptor_test.dart' show FakeAdapter, FakeLocalStore;

/// Exercises the write queue's decision table, which is the part that can
/// lose or duplicate a cashier's money if wrong:
///
/// - enqueue stores the sale and bumps the banner counts,
/// - flush deletes on 2xx (delivered),
/// - a connection-level failure mid-flush keeps the entry pending,
/// - a 422 parks the entry as `failed` and skips it on the next flush,
/// - a 401 stops the run without touching anything,
/// - shop scoping: shop A's flush never posts shop B's entries,
/// - single-flight: two concurrent flushes produce one set of POSTs,
/// - the flag off means no enqueue, no flush — the exact Phase-1 behaviour.
void main() {
  const shopId = 'shop-1';

  late FakeLocalStore store;
  late FakeAdapter adapter;
  late Dio dio;
  late OutboxQueue queue;

  OutboxQueue buildQueue({Future<String?> Function()? currentShopId}) =>
      OutboxQueue(
        dio: dio,
        store: store,
        currentShopId: currentShopId ?? () async => shopId,
      );

  Map<String, dynamic> salePayload({String voucher = 'V-001'}) => {
    'voucherNo': voucher,
    'orderId': 'order-1',
    'grandTotal': 1500,
    'items': [
      {'quantity': 2, 'unitPrice': 750},
    ],
  };

  setUp(() {
    store = FakeLocalStore();
    adapter = FakeAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://pos.test/api/v1'));
    dio.httpClientAdapter = adapter;
    OfflineWrites.enabled = true;
    queue = buildQueue();
  });

  tearDown(() {
    OfflineWrites.reset();
  });

  group('enqueue', () {
    test('stores the sale and updates both counters', () async {
      final queued = await queue.enqueue(kind: 'sale', payload: salePayload());

      expect(queued, isTrue);
      expect(queue.pendingCount.value, 1);
      expect(queue.failedCount.value, 0);

      final pending = await store.outboxPending(shopId: shopId);
      expect(pending, hasLength(1));
      expect(pending.single.kind, 'sale');
      expect(jsonDecode(pending.single.payload), salePayload());
    });

    test('returns false with no signed-in shop, leaving the outbox empty',
        () async {
      final queued = await buildQueue(
        currentShopId: () async => null,
      ).enqueue(kind: 'sale', payload: salePayload());

      expect(queued, isFalse);
      expect(store.outbox, isEmpty);
    });
  });

  group('flush', () {
    test('deletes every entry after a successful 201', () async {
      adapter.statusCode = 201;
      await queue.enqueue(kind: 'sale', payload: salePayload());

      final result = await queue.flush();

      expect(result.synced, 1);
      expect(result.rejected, 0);
      expect(result.remaining, 0);
      expect(store.outbox, isEmpty);
      expect(queue.pendingCount.value, 0);
    });

    test('sends the client UUID as Idempotency-Key', () async {
      adapter.statusCode = 201;
      await queue.enqueue(kind: 'sale', payload: salePayload());

      final dioForHeader = Dio(
        BaseOptions(baseUrl: 'https://pos.test/api/v1'),
      );
      dioForHeader.httpClientAdapter = HeaderRecordingAdapter();
      final headerQueue = OutboxQueue(
        dio: dioForHeader,
        store: store,
        currentShopId: () async => shopId,
      );
      await headerQueue.flush();

      final recorded = (dioForHeader.httpClientAdapter
              as HeaderRecordingAdapter)
          .headers;
      expect(recorded['Idempotency-Key'], isNotEmpty);
    });

    test('a connection-level failure keeps the entry pending', () async {
      adapter.networkDown = true;
      await queue.enqueue(kind: 'sale', payload: salePayload());

      final result = await queue.flush();

      expect(result.synced, 0);
      expect(result.remaining, 1);
      expect(store.outbox.single.status, 'pending');
      expect(queue.pendingCount.value, 1);
    });

    test('a 422 parks the entry as failed and skips it on the next flush',
        () async {
      adapter.statusCode = 422;
      adapter.body = {'message': 'Insufficient stock'};
      await queue.enqueue(kind: 'sale', payload: salePayload());

      final result = await queue.flush();

      expect(result.rejected, 1);
      expect(store.outbox.single.status, 'failed');
      expect(queue.failedCount.value, 1);

      // Second flush must not retry the rejected entry: only POSTs for
      // `pending` entries ever hit the wire.
      adapter.statusCode = 201;
      final retry = await queue.flush();
      expect(retry.synced, 0);
      expect(adapter.fetches, 1); // only the first flush's POST
    });

    test('a 401 stops the run and leaves the entry pending', () async {
      adapter.statusCode = 401;
      await queue.enqueue(kind: 'sale', payload: salePayload());

      final result = await queue.flush();

      expect(result.synced, 0);
      expect(store.outbox.single.status, 'pending');
    });

    test('stops on the first connection failure rather than burning the queue',
        () async {
      // Serves one 201 then the network dies: the flush must deliver the
      // first sale, notice the outage on the second, and stop with the
      // rest of the queue intact — not fire every POST into a dead link.
      final dying = DieAfterAdapter(failAfter: 1);
      final dyingDio = Dio(BaseOptions(baseUrl: 'https://pos.test/api/v1'));
      dyingDio.httpClientAdapter = dying;
      final dyingQueue = OutboxQueue(
        dio: dyingDio,
        store: store,
        currentShopId: () async => shopId,
      );
      await store.outboxEnqueue(
        clientUuid: 'entry-a',
        kind: 'sale',
        payload: jsonEncode(salePayload(voucher: 'A')),
        shopId: shopId,
      );
      await store.outboxEnqueue(
        clientUuid: 'entry-b',
        kind: 'sale',
        payload: jsonEncode(salePayload(voucher: 'B')),
        shopId: shopId,
      );

      final result = await dyingQueue.flush();

      expect(result.synced, 1);
      expect(result.remaining, 1);
      expect(dying.calls, 2); // second call attempted, then stopped
      expect(store.outbox.single.clientUuid, 'entry-b');
    });

    test('flushes only the current shop entries', () async {
      adapter.statusCode = 201;
      await queue.enqueue(kind: 'sale', payload: salePayload(voucher: 'A'));
      // Another shop's sale is in the queue.
      await store.outboxEnqueue(
        clientUuid: 'other-shop-entry',
        kind: 'sale',
        payload: jsonEncode(salePayload(voucher: 'B')),
        shopId: 'shop-2',
      );

      final result = await queue.flush();

      expect(result.synced, 1);
      expect(store.outbox, hasLength(1));
      expect(store.outbox.single.shopId, 'shop-2');
    });

    test('two concurrent flushes produce one run of POSTs', () async {
      adapter.statusCode = 201;
      await queue.enqueue(kind: 'sale', payload: salePayload());

      final results = await Future.wait([queue.flush(), queue.flush()]);

      // One flush did the work; the other short-circuited as empty.
      expect(
        results.map((r) => r.synced).reduce((a, b) => a + b),
        1,
      );
      expect(adapter.fetches, 1);
    });

    test('an unknown kind is parked as failed without a network call',
        () async {
      await store.outboxEnqueue(
        clientUuid: 'weird-entry',
        kind: 'not-a-real-kind',
        payload: '{}',
        shopId: shopId,
      );

      final result = await queue.flush();

      expect(result.rejected, 1);
      expect(adapter.fetches, 0);
    });

    test('no signed-in shop is a no-op, not an error', () async {
      await queue.enqueue(kind: 'sale', payload: salePayload());

      final result = await buildQueue(
        currentShopId: () async => null,
      ).flush();

      expect(result, FlushResult.empty);
      expect(adapter.fetches, 0);
    });
  });

  group('isConnectionLevel', () {
    DioException connectionError() => DioException(
      requestOptions: RequestOptions(path: '/sales'),
      type: DioExceptionType.connectionError,
    );

    DioException socketError() => DioException(
      requestOptions: RequestOptions(path: '/sales'),
      type: DioExceptionType.unknown,
      error: const SocketException('network is down'),
    );

    DioException badResponse() => DioException(
      requestOptions: RequestOptions(path: '/sales'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/sales'),
        statusCode: 422,
      ),
    );

    DioException sendTimeout() => DioException(
      requestOptions: RequestOptions(path: '/sales'),
      type: DioExceptionType.sendTimeout,
    );

    test('connectionError is deliverable', () {
      expect(OutboxQueue.isConnectionLevel(connectionError()), isTrue);
    });

    test('raw SocketException (unknown) is deliverable', () {
      expect(OutboxQueue.isConnectionLevel(socketError()), isTrue);
    });

    test('a bad response is not — the server answered', () {
      expect(OutboxQueue.isConnectionLevel(badResponse()), isFalse);
    });

    test('a timeout is not — the request may have been processed', () {
      expect(OutboxQueue.isConnectionLevel(sendTimeout()), isFalse);
    });
  });

  group('compound sale-from-draft', () {
    /// The compound payload: a draft-order body and a sale body, the sale's
    /// orderId left empty for the flush to fill in.
    Map<String, dynamic> compoundPayload() => {
      'draft': {
        'userName': 'Cashier',
        'voucherNo': 'INV-draft1',
        'orderId': 'ORD-draft1',
        'items': [
          {'productId': 1, 'productName': 'Tea', 'quantity': 2,
           'unitPrice': 750, 'subtotal': 1500},
        ],
        'grandTotal': 1500,
        'status': 'draft',
      },
      'sale': {
        'userName': 'Cashier',
        'voucherNo': 'INV-sale1',
        'orderId': '',
        'items': [
          {'productId': 1, 'productName': 'Tea', 'quantity': 2,
           'unitPrice': 750, 'subtotal': 1500},
        ],
        'grandTotal': 1500,
      },
    };

    test('posts the draft, captures its id, then posts the sale with it',
        () async {
      final routing = RoutingAdapter()
        ..respond('/api/v1/orders', 201, body: {'id': 42})
        ..respond('/api/v1/sales', 201, body: {'id': 7});
      final routeDio = Dio(BaseOptions(baseUrl: 'https://pos.test/api/v1'));
      routeDio.httpClientAdapter = routing;
      final routeQueue = OutboxQueue(
        dio: routeDio,
        store: store,
        currentShopId: () async => shopId,
      );

      await store.outboxEnqueue(
        clientUuid: 'compound-1',
        kind: 'sale-from-draft',
        payload: jsonEncode(compoundPayload()),
        shopId: shopId,
      );

      final result = await routeQueue.flush();

      expect(result.synced, 1);
      expect(store.outbox, isEmpty);
      // The sale POST carried the draft's server id, not the empty
      // placeholder.
      final saleRequest = routing.requests
          .firstWhere((r) => r.path.endsWith('/sales'));
      expect(saleRequest.body['orderId'], '42');
    });

    test('a network death between the two POSTs resumes at the sale half',
        () async {
      // First run: draft succeeds, sale half dies.
      final first = RoutingAdapter()
        ..respond('/api/v1/orders', 201, body: {'id': 42})
        ..dieOn('/api/v1/sales');
      final firstDio = Dio(BaseOptions(baseUrl: 'https://pos.test/api/v1'));
      firstDio.httpClientAdapter = first;
      final firstQueue = OutboxQueue(
        dio: firstDio,
        store: store,
        currentShopId: () async => shopId,
      );
      await store.outboxEnqueue(
        clientUuid: 'compound-2',
        kind: 'sale-from-draft',
        payload: jsonEncode(compoundPayload()),
        shopId: shopId,
      );

      final partial = await firstQueue.flush();
      expect(partial.synced, 0);
      expect(partial.remaining, 1);
      // The id from the successful draft half is persisted.
      expect(store.outbox.single.resolvedServerId, '42');

      // Second run: the draft POST must NOT repeat; only the sale goes out.
      final second = RoutingAdapter()
        ..respond('/api/v1/sales', 201, body: {'id': 8});
      final secondDio = Dio(BaseOptions(baseUrl: 'https://pos.test/api/v1'));
      secondDio.httpClientAdapter = second;
      final secondQueue = OutboxQueue(
        dio: secondDio,
        store: store,
        currentShopId: () async => shopId,
      );

      final resumed = await secondQueue.flush();
      expect(resumed.synced, 1);
      expect(store.outbox, isEmpty);
      // No second draft: the only POST was the sale.
      expect(second.requests.map((r) => r.path), ['/api/v1/sales']);
      expect(second.requests.single.body['orderId'], '42');
    });

    test('a refused draft parks the entry and never attempts the sale',
        () async {
      final routing = RoutingAdapter()
        ..respond('/api/v1/orders', 422, body: {'message': 'Insufficient stock'})
        ..respond('/api/v1/sales', 201, body: {'id': 9});
      final routeDio = Dio(BaseOptions(baseUrl: 'https://pos.test/api/v1'));
      routeDio.httpClientAdapter = routing;
      final routeQueue = OutboxQueue(
        dio: routeDio,
        store: store,
        currentShopId: () async => shopId,
      );
      await store.outboxEnqueue(
        clientUuid: 'compound-3',
        kind: 'sale-from-draft',
        payload: jsonEncode(compoundPayload()),
        shopId: shopId,
      );

      final result = await routeQueue.flush();

      expect(result.rejected, 1);
      expect(store.outbox.single.status, 'failed');
      // The sale POST never fired — there was no draft to convert.
      expect(routing.requests.map((r) => r.path), ['/api/v1/orders']);
    });
  });

  group('order-items', () {
    Map<String, dynamic> orderItemsPayload() => {
      'orderId': '55',
      'items': [
        {'productId': 3, 'productName': 'Cake', 'quantity': 1,
         'unitPrice': 900, 'subtotal': 900},
      ],
    };

    test('posts to /orders/{id}/items with the wrapped items body',
        () async {
      final routing = RoutingAdapter()
        ..respond('/api/v1/orders/55/items', 200, body: {'id': 55});
      final routeDio = Dio(BaseOptions(baseUrl: 'https://pos.test/api/v1'));
      routeDio.httpClientAdapter = routing;
      final routeQueue = OutboxQueue(
        dio: routeDio,
        store: store,
        currentShopId: () async => shopId,
      );
      await store.outboxEnqueue(
        clientUuid: 'items-1',
        kind: 'order-items',
        payload: jsonEncode(orderItemsPayload()),
        shopId: shopId,
      );

      final result = await routeQueue.flush();

      expect(result.synced, 1);
      expect(store.outbox, isEmpty);
      final request = routing.requests.single;
      expect(request.path, '/api/v1/orders/55/items');
      expect(request.body['items'], hasLength(1));
    });

    test('a refused append stops the run so the sale behind it waits',
        () async {
      final routing = RoutingAdapter()
        ..respond('/api/v1/orders/55/items', 422,
            body: {'message': 'Insufficient stock'})
        ..respond('/api/v1/sales', 201, body: {'id': 1});
      final routeDio = Dio(BaseOptions(baseUrl: 'https://pos.test/api/v1'));
      routeDio.httpClientAdapter = routing;
      final routeQueue = OutboxQueue(
        dio: routeDio,
        store: store,
        currentShopId: () async => shopId,
      );
      await store.outboxEnqueue(
        clientUuid: 'items-2',
        kind: 'order-items',
        payload: jsonEncode(orderItemsPayload()),
        shopId: shopId,
      );
      await store.outboxEnqueue(
        clientUuid: 'sale-behind',
        kind: 'sale',
        payload: jsonEncode(salePayload()),
        shopId: shopId,
      );

      final result = await routeQueue.flush();

      expect(result.rejected, 1);
      // The refused append stopped the run: the sale entry is untouched.
      expect(store.outbox.map((e) => e.clientUuid),
          containsAll(['items-2', 'sale-behind']));
      expect(store.outbox.firstWhere((e) => e.clientUuid == 'items-2').status,
          'failed');
      expect(store.outbox.firstWhere((e) => e.clientUuid == 'sale-behind').status,
          'pending');
      // And the sale POST never fired.
      expect(routing.requests.map((r) => r.path),
          ['/api/v1/orders/55/items']);
    });
  });
}

/// A per-path fake server: register the response each route should give,
/// or arm a route to kill the connection instead.
class RoutingAdapter implements HttpClientAdapter {
  final Map<String, ({int status, Object? body})> _responses = {};
  final Set<String> _dying = {};
  final List<({String path, Map<String, dynamic> body})> requests = [];

  void respond(String path, int status, {Object? body}) =>
      _responses[path] = (status: status, body: body);

  void dieOn(String path) => _dying.add(path);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (_dying.contains(path)) {
      throw const SocketException('network died');
    }
    Object? requestBody;
    if (requestStream != null) {
      final bytes = await requestStream.expand((chunk) => chunk).toList();
      if (bytes.isNotEmpty) {
        requestBody = jsonDecode(String.fromCharCodes(bytes));
      }
    }
    requests.add((
      path: path,
      body: requestBody is Map<String, dynamic> ? requestBody : const {},
    ));
    final response = _responses[path];
    if (response == null) {
      throw SocketException('no route registered for $path');
    }
    return ResponseBody.fromString(
      jsonEncode(response.body ?? const {}),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Serves [failAfter] successful responses, then throws a
/// [SocketException] on every subsequent call — a network that dies
/// mid-flush, which is the only way to exercise the "stop, keep the rest
/// pending" branch without a real outage.
class DieAfterAdapter implements HttpClientAdapter {
  DieAfterAdapter({required this.failAfter});

  final int failAfter;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (calls > failAfter) {
      throw const SocketException('network died mid-flush');
    }
    return ResponseBody.fromString(
      '{"id": 1}',
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Records every header it sees so the `Idempotency-Key` claim can be
/// verified without a mock server.
class HeaderRecordingAdapter implements HttpClientAdapter {
  final Map<String, String> headers = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = options.headers['Idempotency-Key'];
    if (key != null) headers['Idempotency-Key'] = key.toString();
    return ResponseBody.fromString(
      '{}',
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
