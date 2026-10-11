import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_notification.dart';

/// Local, persisted history of push notifications.
///
/// FCM delivers a notification message to the system tray only — while the
/// app is backgrounded the Dart code never sees it — so the store is fed
/// from the paths where the app *is* running: the foreground listener and
/// the tap handlers (`onMessageOpenedApp`, `getInitialMessage`), which fire
/// when the user opens a tray entry from background or terminated state.
///
/// Same ValueNotifier + SharedPreferences shape as [CartStore].
class NotificationStore extends ValueNotifier<List<AppNotification>> {
  static final NotificationStore instance = NotificationStore._();
  NotificationStore._() : super(const []);

  static const String _storageKey = 'notifications_v1';

  /// Oldest entries fall off; the page is a history, not an archive.
  static const int _maxItems = 100;

  /// Two arrivals closer together than this with identical content are the
  /// same push seen twice (foreground save + tap save), not two alerts.
  static const Duration _duplicateWindow = Duration(minutes: 10);

  bool _loaded = false;

  int get unreadCount => value.where((n) => !n.read).length;

  bool get hasUnread => unreadCount > 0;

  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    await _loadFromDisk();
  }

  /// Re-reads storage unconditionally. Only [init] should set [_loaded];
  /// this exists for pull-to-refresh, which must reflect whatever is on disk
  /// now rather than trust the first load.
  Future<void> refresh() async {
    await _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      value = list;
    } catch (_) {
      // Corrupted storage is treated as an empty history, same as the cart.
    }
  }

  /// Records a received message. Safe to call from every delivery path:
  /// duplicates inside [_duplicateWindow] are dropped and [init] is awaited
  /// first so a late load cannot clobber what was just added.
  Future<void> add({
    required String? messageId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic> data = const {},
  }) async {
    await init();
    if (title.isEmpty && body.isEmpty) return;

    final now = DateTime.now();
    final signature = '$type|${data['product_id'] ?? ''}|$title|$body';
    final isDuplicate = value.any(
      (n) =>
          n.signature == signature &&
          now.difference(n.receivedAt) < _duplicateWindow,
    );
    if (isDuplicate) return;

    final item = AppNotification(
      id: (messageId != null && messageId.isNotEmpty)
          ? messageId
          : '${now.microsecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      data: data,
      receivedAt: now,
      read: false,
    );

    // Newest first; the id check covers the rare case of the same FCM
    // message id arriving through two paths with slightly different timing.
    if (value.any((n) => n.id == item.id)) return;

    final updated = [item, ...value].take(_maxItems).toList();
    value = List.of(updated);
    await _persist(updated);
  }

  Future<void> markRead(String id) async {
    final index = value.indexWhere((n) => n.id == id);
    if (index < 0 || value[index].read) return;
    final updated = [...value];
    updated[index] = updated[index].copyWith(read: true);
    value = List.of(updated);
    await _persist(updated);
  }

  Future<void> markAllRead() async {
    if (!hasUnread) return;
    value = [for (final n in value) n.copyWith(read: true)];
    await _persist(value);
  }

  Future<void> remove(String id) async {
    final updated = value.where((n) => n.id != id).toList();
    if (updated.length == value.length) return;
    value = List.of(updated);
    await _persist(updated);
  }

  Future<void> clear() async {
    value = const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {
      // Non-critical: history is empty in memory either way.
    }
  }

  Future<void> _persist(List<AppNotification> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // Persistence failure is non-critical; keep history in memory.
    }
  }
}
