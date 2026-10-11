import 'package:flutter/foundation.dart';

/// A push notification the app has received, kept locally so the in-app
/// notification page can show what was pushed even after the system tray
/// entry is gone.
@immutable
class AppNotification {
  final String id;

  /// Notification title, e.g. "Out of Stock".
  final String title;

  /// Notification body, e.g. "Product X is out of stock".
  final String body;

  /// Alert kind from the payload (`stock_out`, `low_stock`,
  /// `stock_restored`, ...). Drives the icon and accent on the page.
  final String type;

  /// Raw FCM data map. Kept whole so future screens can act on any field
  /// (product id, sku, quantities) without a schema change here.
  final Map<String, dynamic> data;

  /// When the app received it, used for ordering and the "5m ago" label.
  final DateTime receivedAt;

  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.receivedAt,
    required this.read,
  });

  String? get productId {
    final raw = data['product_id'] ?? data['productId'];
    if (raw == null) return null;
    final s = raw.toString();
    return s.isEmpty ? null : s;
  }

  /// Package id for pushes that target a package (package-out alerts).
  String? get packageId {
    final raw = data['package_id'] ?? data['packageId'];
    if (raw == null) return null;
    final s = raw.toString();
    return s.isEmpty ? null : s;
  }

  /// Tab buckets shown on the notifications page, in tab order. The daily
  /// report payload and these buckets stay in sync: everything the backend
  /// pushes today carries `category: alert` (or no category at all, for
  /// saves that predate the field).
  static const List<String> categories = ['system', 'alert', 'news'];

  /// Which tab this entry belongs to. The backend may set it explicitly via
  /// `data.category`; older saves predate the field, and unknown values fall
  /// back to `alert` — an entry must never fall out of every tab.
  String get category {
    final explicit = (data['category'] ?? '').toString();
    return categories.contains(explicit) ? explicit : 'alert';
  }

  /// Content signature used to suppress double-saves. The same message can
  /// arrive through more than one path (foreground listener and a tap on the
  /// tray entry, for example), and the stock-out job cools down per product
  /// for 24h — so identical content that close together is the same alert.
  String get signature => '$type|${productId ?? ''}|$title|$body';

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        data: data,
        receivedAt: receivedAt,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'receivedAt': receivedAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: json['type'] as String? ?? '',
        data: (json['data'] as Map<String, dynamic>?) ?? const {},
        receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ??
            DateTime.now(),
        read: json['read'] as bool? ?? false,
      );
}
