import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/core/network/api_client.dart';

/// Outcome of one flush pass, for callers (and tests) that care what
/// happened rather than just that it finished.
class FlushResult {
  const FlushResult({
    this.synced = 0,
    this.rejected = 0,
    this.remaining = 0,
  });

  /// Entries the server accepted.
  final int synced;

  /// Entries the server refused (validation, insufficient stock). They are
  /// parked as `failed` and will not be retried without a human decision.
  final int rejected;

  /// Entries still queued — the network gave out, or the server is having
  /// a bad time; the next flush picks them up.
  final int remaining;

  static const empty = FlushResult();
}

/// Delivers queued writes to the server, one at a time, oldest first.
///
/// ## The contract with the caller
///
/// `enqueue` is called from a request that has *just failed at the
/// connection level*. If it returns true, the caller reports success to the
/// cashier — the sale is recorded on this device and will reach the server
/// later. If it returns false (no signed-in shop to attribute it to) or
/// throws (platform with no local database), the caller must let the
/// original error surface: never claim a sale was taken when nothing
/// recorded it.
///
/// ## Entry kinds
///
/// - `sale` — a plain `POST /sales` against a draft order the server
///   already knows about (Phase 2).
/// - `order-items` — `POST /orders/{id}/items` appending to a server-side
///   draft while offline. Enqueued *before* the sale entry that will later
///   convert that draft, so FIFO guarantees stock is deducted for the
///   appended items before the sale claims them.
/// - `sale-from-draft` — the compound pair for a cart that was *built*
///   offline and never had a server draft: `POST /orders` (create the
///   draft) then `POST /sales` (convert it). The server id from the first
///   half is persisted in `resolvedServerId` the moment it arrives, so a
///   network death between the two POSTs resumes at the sale half instead
///   of creating a second draft.
///
/// ## Flush decisions, in order of priority
///
/// | Outcome of a POST | Entry | Why |
/// |---|---|---|
/// | 2xx | deleted | delivered |
/// | connection-level failure | stays `pending`, **stop** | the network gave out mid-run; the rest cannot go either |
/// | 401 / 429 | stays `pending`, **stop** | session or throttle — retrying the next entry would fail the same way |
/// | other 4xx | `failed` with the server's message | the server *answered*: stock gone, validation refused. Retrying unchanged is pointless; a human must decide (refund, adjust, edit) |
/// | 5xx | stays `pending`, **stop** | the server is unwell; do not machine-gun it with the rest of the queue |
///
/// A refused `order-items` additionally **stops the run**: the sale entry
/// behind it (same card, enqueued seconds later) would claim revenue for
/// stock the ledger never deducted. Independent entries wait for the next
/// flush rather than post unbacked.
///
/// ## Why POSTs carry `Idempotency-Key`
///
/// The header is ignored by today's backend. When the server grows a
/// unique column for it, the same queue becomes safe to flush after an
/// ambiguous failure without a code change — see [OfflineWrites] for why
/// that ambiguity currently keeps the feature behind a flag.
class OutboxQueue {
  OutboxQueue({
    Dio? dio,
    LocalStore? store,
    Future<String?> Function()? currentShopId,
  }) : _dio = dio ?? ApiClient.instance,
       _store = store ?? LocalStore.instance,
       _currentShopId = currentShopId ?? SessionStore.currentShopId;

  final Dio _dio;
  final LocalStore _store;
  final Future<String?> Function() _currentShopId;

  /// For the banner: how many of the current shop's writes are waiting.
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  /// For the banner: how many were refused by the server and need a
  /// human.
  final ValueNotifier<int> failedCount = ValueNotifier<int>(0);

  bool _flushing = false;

  static OutboxQueue? _instance;

  /// Process-wide instance; see `LocalStore.instance` on the static
  /// singleton style used by this app's core services.
  static OutboxQueue get instance => _instance ??= OutboxQueue();

  @visibleForTesting
  static set instanceForTesting(OutboxQueue? queue) => _instance = queue;

  /// Resets the singleton instance. Useful for hot restart.
  static void reset() {
    _instance = null;
  }

  /// True when [e] means "the request never reached the server" closely
  /// enough to be worth replaying.
  ///
  /// Timeouts are deliberately excluded: a `send`/`receive` timeout means
  /// the POST *may* have been processed with the response lost, and
  /// replaying that is how a till sells the same basket twice. A lost
  /// response stays an error the cashier sees, which is recoverable; a
  /// silent duplicate is not.
  static bool isConnectionLevel(DioException e) {
    if (e.response != null) return false;
    switch (e.type) {
      case DioExceptionType.connectionError:
      // Raw transport failures (connection refused, DNS) arrive as
      // `unknown` with no response attached.
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
        return false;
    }
  }

  /// Stores one write for later delivery. Returns false when there is no
  /// session to attribute it to — the caller must then let the original
  /// error through rather than report a success nothing recorded.
  Future<bool> enqueue({
    required String kind,
    required Map<String, dynamic> payload,
  }) async {
    final shopId = await _currentShopId();
    if (shopId == null || shopId.isEmpty) return false;

    await _store.outboxEnqueue(
      clientUuid: newClientUuid(),
      kind: kind,
      payload: jsonEncode(payload),
      shopId: shopId,
    );
    await refreshCounts();
    return true;
  }

  /// Sends every pending entry for the current shop, oldest first.
  ///
  /// Single-flight: a reconnect that fires the sync manager's periodic
  /// timer and its link listener at once still produces one run, not a
  /// burst of duplicate POSTs — which matters more here than anywhere
  /// else, because these POSTs create sales.
  ///
  /// The guard is acquired synchronously, before the first await: two
  /// flushes arriving in the same microtask must still count as one run,
  /// so the second has to see the flag already set rather than race it.
  Future<FlushResult> flush() async {
    if (_flushing) return FlushResult.empty;
    _flushing = true;
    try {
      final shopId = await _currentShopId();
      if (shopId == null || shopId.isEmpty) return FlushResult.empty;

      final entries = await _store.outboxPending(shopId: shopId);
      var synced = 0;
      var rejected = 0;

      for (final entry in entries) {
        final outcome = await _deliverEntry(entry);
        switch (outcome) {
          case _Delivery.accepted:
            await _store.outboxDelete(clientUuid: entry.clientUuid);
            synced++;
          case _Delivery.refused:
            rejected++;
            // A refused draft-append means the sale behind it (same card,
            // enqueued moments later) would claim revenue for stock the
            // ledger never deducted. Stop: independent entries wait for
            // the next flush rather than post unbacked.
            if (entry.kind == 'order-items') {
              return FlushResult(
                synced: synced,
                rejected: rejected,
                remaining: await _pendingTotal(shopId),
              );
            }
          case _Delivery.stop:
            // Network gone or server unwell: everything behind this entry
            // waits for the next flush too. Stop is a *break*, not an
            // error — the remaining queue is intact by design.
            return FlushResult(
              synced: synced,
              rejected: rejected,
              remaining: await _pendingTotal(shopId),
            );
        }
      }

      return FlushResult(
        synced: synced,
        rejected: rejected,
        remaining: await _pendingTotal(shopId),
      );
    } finally {
      _flushing = false;
      // Every exit path — success, stop, or no session — republishes the
      // real table state, so the banner counts cannot drift from storage.
      await refreshCounts();
    }
  }

  /// Dispatches one entry to the right delivery routine. Kept separate
  /// from the flush loop so each kind's decision table stays readable.
  Future<_Delivery> _deliverEntry(
    ({
      String clientUuid,
      String kind,
      String payload,
      String? resolvedServerId,
    })
    entry,
  ) async {
    switch (entry.kind) {
      case 'sale':
        return _deliver('/sales', entry.clientUuid, entry.payload);
      case 'order-items':
        final body = jsonDecode(entry.payload) as Map<String, dynamic>;
        final orderId = body['orderId']?.toString();
        if (orderId == null || orderId.isEmpty) {
          await _store.outboxRecordAttempt(
            clientUuid: entry.clientUuid,
            rejected: true,
            error: 'order-items entry has no orderId',
          );
          return _Delivery.refused;
        }
        return _deliver(
          '/orders/$orderId/items',
          entry.clientUuid,
          jsonEncode({'items': body['items']}),
        );
      case 'sale-from-draft':
        return _deliverSaleFromDraft(entry);
      default:
        await _store.outboxRecordAttempt(
          clientUuid: entry.clientUuid,
          rejected: true,
          error: 'Unknown outbox kind "${entry.kind}"',
        );
        return _Delivery.refused;
    }
  }

  /// The compound pair: create the draft order, then convert it to a sale.
  ///
  /// The server id returned by the draft half is persisted before the sale
  /// half is attempted. If the network dies between the two POSTs the
  /// entry stays `pending` with `resolvedServerId` set, and the next flush
  /// skips straight to the sale — retrying the draft half would create a
  /// second order row and pin its stock twice.
  Future<_Delivery> _deliverSaleFromDraft(
    ({
      String clientUuid,
      String kind,
      String payload,
      String? resolvedServerId,
    })
    entry,
  ) async {
    final body = jsonDecode(entry.payload) as Map<String, dynamic>;
    final draft = body['draft'];
    final sale = body['sale'];
    if (draft is! Map<String, dynamic> || sale is! Map<String, dynamic>) {
      await _store.outboxRecordAttempt(
        clientUuid: entry.clientUuid,
        rejected: true,
        error: 'sale-from-draft payload is missing draft or sale body',
      );
      return _Delivery.refused;
    }

    var serverId = entry.resolvedServerId;
    if (serverId == null) {
      final draftResult = await _deliverJson(
        '/orders',
        entry.clientUuid,
        draft,
      );
      switch (draftResult.outcome) {
        case _Delivery.refused:
          // Draft refused (usually insufficient stock): the sale must not
          // follow — there is nothing to convert.
          return _Delivery.refused;
        case _Delivery.stop:
          return _Delivery.stop;
        case _Delivery.accepted:
          final id = draftResult.serverId;
          if (id == null) {
            // A draft POST returning plain 2xx with no usable id cannot be
            // chained; park it rather than post a sale against an unknown
            // order.
            await _store.outboxRecordAttempt(
              clientUuid: entry.clientUuid,
              rejected: true,
              error: 'Draft order response carried no id',
            );
            return _Delivery.refused;
          }
          serverId = id;
          await _store.outboxSetResolvedId(
            clientUuid: entry.clientUuid,
            serverId: id,
          );
      }
    }

    // The sale body is rewritten to reference the server's order id —
    // the local placeholder (`local:…`) never reaches the wire.
    final saleBody = {...sale, 'orderId': serverId};
    return (await _deliverJson('/sales', entry.clientUuid, saleBody)).outcome;
  }

  /// POSTs [body], reporting the outcome plus — when the response carries a
  /// primary key under `id` — the id the server assigned. The compound
  /// draft half needs that id; plain deliveries ignore it.
  Future<({_Delivery outcome, String? serverId})> _deliverJson(
    String endpoint,
    String clientUuid,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: body,
        options: Options(headers: {'Idempotency-Key': clientUuid}),
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        return (
          outcome: _Delivery.accepted,
          serverId: _serverAssignedId(response.data),
        );
      }
      if (status >= 400 && status < 500) {
        await _store.outboxRecordAttempt(
          clientUuid: clientUuid,
          rejected: true,
          error: 'Server returned $status',
        );
        return (outcome: _Delivery.refused, serverId: null);
      }
      await _store.outboxRecordAttempt(clientUuid: clientUuid);
      return (outcome: _Delivery.stop, serverId: null);
    } on DioException catch (e) {
      return (outcome: await _mapDioFailure(e, clientUuid), serverId: null);
    }
  }

  /// Pulls the primary key out of a create-response. The order endpoint
  /// returns the row id under `id`; anything else is treated as "no id".
  String? _serverAssignedId(dynamic data) {
    if (data is Map && data['id'] != null) return data['id'].toString();
    return null;
  }

  Future<_Delivery> _mapDioFailure(DioException e, String clientUuid) async {
    if (e.response == null) {
      await _store.outboxRecordAttempt(clientUuid: clientUuid);
      return _Delivery.stop;
    }
    final status = e.response!.statusCode ?? 0;
    if (status == 401 || status == 429 || status >= 500) {
      await _store.outboxRecordAttempt(clientUuid: clientUuid);
      return _Delivery.stop;
    }
    if (status >= 400 && status < 500) {
      await _store.outboxRecordAttempt(
        clientUuid: clientUuid,
        rejected: true,
        error: _serverMessage(e),
      );
      return _Delivery.refused;
    }
    await _store.outboxRecordAttempt(clientUuid: clientUuid);
    return _Delivery.stop;
  }

  Future<_Delivery> _deliver(
    String endpoint,
    String clientUuid,
    String payload,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: jsonDecode(payload),
        options: Options(headers: {'Idempotency-Key': clientUuid}),
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) return _Delivery.accepted;

      // A non-2xx that dio did not raise (validateStatus quirks): treat a
      // client error as refused, anything else as stop.
      if (status >= 400 && status < 500) {
        await _store.outboxRecordAttempt(
          clientUuid: clientUuid,
          rejected: true,
          error: 'Server returned $status',
        );
        return _Delivery.refused;
      }
      await _store.outboxRecordAttempt(clientUuid: clientUuid);
      return _Delivery.stop;
    } on DioException catch (e) {
      return _mapDioFailure(e, clientUuid);
    }
  }

  /// Reloads both counts from storage. Called at startup, after every
  /// enqueue, and after every flush so the banner never drifts from what
  /// the table actually holds.
  Future<void> refreshCounts() async {
    final shopId = await _currentShopId();
    if (shopId == null || shopId.isEmpty) {
      pendingCount.value = 0;
      failedCount.value = 0;
      return;
    }
    pendingCount.value = await _store.outboxCount(
      shopId: shopId,
      status: 'pending',
    );
    failedCount.value = await _store.outboxCount(
      shopId: shopId,
      status: 'failed',
    );
  }

  Future<int> _pendingTotal(String shopId) =>
      _store.outboxCount(shopId: shopId, status: 'pending');

  String _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return 'Server returned ${e.response?.statusCode ?? 'an error'}';
  }

  /// RFC 4122 v4 UUID from a secure source — this value is the future
  /// idempotency key, so predictable output would defeat it. Public so the
  /// offline cart can mint equally collision-resistant local order ids.
  static String newClientUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

enum _Delivery { accepted, refused, stop }
