import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:posfrontend/features/notifications/data/notification_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the rule that notification history belongs to a session, not to the
/// device: signing out, or signing in to a different shop, must empty it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storedNotification = jsonEncode([
    {
      'id': 'n1',
      'title': 'Out of Stock',
      'body': 'Soap is out of stock',
      'type': 'stock_out',
      'data': {'shop_id': 'shop-a'},
      'receivedAt': DateTime(2026, 1, 1).toIso8601String(),
      'read': false,
    },
  ]);

  setUp(() {
    // The real store opens a SQLite file through path_provider; the no-op
    // store is the same one the web build uses and keeps the test hermetic.
    LocalStore.instanceForTesting = NoopLocalStore();
    NotificationStore.instance.value = const [];
  });

  tearDown(() {
    LocalStore.instanceForTesting = null;
    NotificationStore.instance.value = const [];
  });

  test('sign-out clears the persisted notification history', () async {
    SharedPreferences.setMockInitialValues({
      'session_profile': jsonEncode({'shopId': 'shop-a'}),
      'notifications_v1': storedNotification,
    });
    await NotificationStore.instance.refresh();
    expect(NotificationStore.instance.value, hasLength(1));

    await SessionStore.clear();

    expect(NotificationStore.instance.value, isEmpty);
    expect(NotificationStore.instance.unreadCount, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('notifications_v1'), isNull);
  });

  test('a different shop on login clears the previous history', () async {
    SharedPreferences.setMockInitialValues({
      'session_profile': jsonEncode({'shopId': 'shop-a'}),
      'notifications_v1': storedNotification,
    });
    await NotificationStore.instance.refresh();
    expect(NotificationStore.instance.value, hasLength(1));

    await SessionStore.save({
      'id': 'u1',
      'fullName': 'Owner',
      'email': 'owner@example.com',
      'shopId': 'shop-b',
      'role': 'admin',
    }, 'token');

    expect(NotificationStore.instance.value, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('session_profile')!)['shopId'], 'shop-b');
  });

  test('the same shop keeps its history on login', () async {
    SharedPreferences.setMockInitialValues({
      'session_profile': jsonEncode({'shopId': 'shop-a'}),
      'notifications_v1': storedNotification,
    });
    await NotificationStore.instance.refresh();

    await SessionStore.save({
      'id': 'u1',
      'fullName': 'Owner',
      'email': 'owner@example.com',
      'shopId': 'shop-a',
      'role': 'admin',
    }, 'token');

    expect(NotificationStore.instance.value, hasLength(1));
  });
}
