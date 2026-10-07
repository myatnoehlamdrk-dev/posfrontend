import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/notifications/data/notification_store.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FcmService {
  FcmService._internal();

  static final FcmService instance = FcmService._internal();

  // FirebaseMessaging.instance reads Firebase.app() under the hood, so it
  // must not run as a field initializer: the singleton is constructed before
  // setup() calls Firebase.initializeApp(), and the premature access threw,
  // leaving the service permanently uninitialized with no registered token.
  // Assigned in _setup() after initialization instead.
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _token;
  String? get token => _token;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenSubscription;

  Future<void> initialize() async {
    await _setup();
    await _retrieveToken();
    _listenTokenRefresh();
  }

  /// Sets up FCM without registering the token (called at app startup).
  /// Token registration happens after login via [registerTokenAfterLogin].
  Future<void> setup() async {
    await _setup();
  }

  Future<void> _setup() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _setupLocalNotifications();
    await _listenForegroundMessages();
    await _listenNotificationTaps();
  }

  /// Persists the message the user opened from the tray.
  ///
  /// Android does not run app code while a notification message sits in the
  /// background, so these tap callbacks (and the foreground listener) are the
  /// only moments the Dart side ever sees a push. Without them the in-app
  /// notification page would be empty for anything tapped later.
  Future<void> _listenNotificationTaps() async {
    final messaging = _messaging;
    if (messaging == null) return;
    FirebaseMessaging.onMessageOpenedApp.listen(_saveToStore);
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) await _saveToStore(initial);
    } catch (e) {
      debugPrint('FCM initial message failed: $e');
    }
  }

  Future<void> _saveToStore(RemoteMessage message) async {
    final notification = message.notification;
    final data = Map<String, dynamic>.from(message.data);
    final title =
        notification?.title ?? (data['title'] ?? '').toString();
    final body = notification?.body ?? (data['body'] ?? '').toString();

    // The daily stock report stays ONE entry per day — its per-product
    // breakdown lives in data.products and is shown by the detail screen
    // when the entry is tapped, not as a pile of separate notifications.
    await NotificationStore.instance.add(
      messageId: message.messageId,
      title: title,
      body: body,
      type: (data['type'] ?? '').toString(),
      data: data,
    );
  }

  /// Registers FCM token with backend after successful login.
  Future<void> registerTokenAfterLogin() async {
    await _retrieveToken();
    _listenTokenRefresh();
  }

  Future<void> _requestPermissions() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('FCM permission request failed: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'stock_alerts',
      'Stock Alerts',
      description: 'Notifications for out of stock and low stock alerts',
      importance: Importance.high,
    );

    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Failed to create notification channel: $e');
    }
  }

  Future<void> _listenForegroundMessages() async {
    _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      _saveToStore(message);
      _showLocalNotification(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'stock_alerts',
      'Stock Alerts',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Stock Alert',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  Future<void> _retrieveToken() async {
    final messaging = _messaging;
    if (messaging == null) {
      debugPrint('FCM skipped: setup() has not completed yet');
      return;
    }
    try {
      _token = await messaging.getToken();
      debugPrint('FCM Token: $_token');
      await _registerToken(_token);
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  void _listenTokenRefresh() {
    final messaging = _messaging;
    if (messaging == null) return;
    _tokenSubscription?.cancel();
    _tokenSubscription = messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      debugPrint('FCM Token refreshed: $_token');
      _registerToken(newToken);
    });
  }

  Future<String?> getToken() async {
    if (_token == null) {
      await _retrieveToken();
    }
    return _token;
  }

  Future<void> _registerToken(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      final dio = ApiClient.instance;
      await dio.post(
        '/fcm-tokens',
        data: {
          'token': token,
          'platform': 'android',
        },
      );
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _tokenSubscription?.cancel();
  }

  /// Shows an out-of-stock notification for a product
  Future<void> showOutOfStockNotification({
    required String productName,
    String? sku,
    int currentStock = 0,
  }) async {
    final title = 'Out of Stock Alert';
    final body = '$productName is out of stock!${sku != null ? " (SKU: $sku)" : ""} Current stock: $currentStock';

    await _showLocalNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: title,
          body: body,
        ),
        data: {
          'type': 'out_of_stock',
          'product_name': productName,
          if (sku != null) 'sku': sku,
          'current_stock': currentStock.toString(),
        },
      ),
    );
  }

  /// Shows a low stock notification for a product
  Future<void> showLowStockNotification({
    required String productName,
    String? sku,
    required int currentStock,
    int threshold = 10,
  }) async {
    final title = 'Low Stock Alert';
    final body =
        '$productName is running low! Only $currentStock left (threshold: $threshold).${sku != null ? " (SKU: $sku)" : ""}';

    await _showLocalNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: title,
          body: body,
        ),
        data: {
          'type': 'low_stock',
          'product_name': productName,
          if (sku != null) 'sku': sku,
          'current_stock': currentStock.toString(),
          'threshold': threshold.toString(),
        },
      ),
    );
  }

  /// Shows a stock restored notification
  Future<void> showStockRestoredNotification({
    required String productName,
    String? sku,
    required int newStock,
  }) async {
    final title = 'Stock Restored';
    final body = '$productName has been restocked! New quantity: $newStock.${sku != null ? " (SKU: $sku)" : ""}';

    await _showLocalNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: title,
          body: body,
        ),
        data: {
          'type': 'stock_restored',
          'product_name': productName,
          if (sku != null) 'sku': sku,
          'new_stock': newStock.toString(),
        },
      ),
    );
  }
}
