import 'dart:convert';

import 'package:posfrontend/features/auth/data/models/login_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local record of *who* is signed in and *when the app last used* that
/// session.
///
/// Two jobs, deliberately kept apart from [TokenStorage]:
///
///  - **Identity.** `AuthScope` starts every cold start empty, yet a dozen
///    screens read it (`new_sale_screen`, `profile_screen`, `app_drawer`, the
///    cart) and fall back to placeholders when it is null. The bearer token
///    proves the session is valid but says nothing about the name, role or
///    shop to render, and `GET /auth/me` cannot answer when the device is
///    offline. Caching those five fields is what makes an offline launch land
///    on a usable dashboard instead of an anonymous one.
///
///  - **Idle tracking.** The session rule is "5 days without opening the app
///    ends the session" -- not "5 days from login". The server enforces the
///    same window on its side (see `App\Services\TokenToucher`), but its
///    clock only advances when the device is online, so an offline launch
///    still has to be able to expire a session. That decision is made here,
///    before any network call.
///
/// The bearer token is **not** stored here. It belongs in platform secure
/// storage; this holds only the non-secret profile fields.
class SessionStore {
  SessionStore._();

  /// Idle window after which a session is considered abandoned.
  static const Duration idleWindow = Duration(days: 5);

  static const String _profileKey = 'session_profile';
  static const String _lastUsedKey = 'session_last_used_at';

  /// Persist the profile from `GET /auth/me` and mark the session used.
  ///
  /// [me] is the raw `UserResource` body: `id`, `fullName`, `email`,
  /// `shopId`, `role`. The token itself is passed separately and never
  /// written here.
  ///
  /// Marks the session used because reaching this means the launch decided
  /// the session is alive -- the idle clock is measuring opens, not logins.
  static Future<LoginResponse> save(Map<String, dynamic> me, String token) async {
    final profile = <String, dynamic>{
      'id': me['id']?.toString() ?? '',
      'fullName': (me['fullName'] ?? me['name'])?.toString() ?? '',
      'email': me['email']?.toString() ?? '',
      'shopId': (me['shopId'] ?? me['shop_id'] ?? '').toString(),
      'role': me['role']?.toString() ?? '',
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile));
    await markUsed();

    return _toLoginResponse(profile, token);
  }

  /// Rebuild the session from the cached profile when `/auth/me` could not be
  /// reached. Also marks the session used, for the same reason as [save]: the
  /// launch got far enough to show the dashboard.
  ///
  /// Returns null when there is no cached profile, which is the signal to
  /// sign in again rather than show a dashboard with no identity on it.
  static Future<LoginResponse?> restore(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    await markUsed();
    return _toLoginResponse(decoded, token);
  }

  /// Record that the app was opened now.
  static Future<void> markUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUsedKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// True when the session has been idle for longer than [window].
  ///
  /// A missing timestamp reads as expired rather than as "never used, keep
  /// it". The session can only be as old as the last time somebody opened
  /// the app, so no timestamp means no evidence of a session at all -- which
  /// is also what an install upgrading from before this feature saw, and that
  /// upgrade should ask for a sign-in rather than resurrect a token whose
  /// server-side expiry had long since passed.
  static Future<bool> isIdleExpired({Duration? window}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastUsed = prefs.getInt(_lastUsedKey);
    if (lastUsed == null) return true;

    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastUsed),
    );
    return age > (window ?? idleWindow);
  }

  /// Drop the cached identity and the idle clock.
  ///
  /// Called wherever the bearer token is cleared: a stale profile left behind
  /// after a logout would be restored on the next launch even though the token
  /// it belonged to was gone.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_lastUsedKey);
  }

  static LoginResponse _toLoginResponse(
    Map<String, dynamic> profile,
    String token,
  ) {
    return LoginResponse(
      id: profile['id']?.toString() ?? '',
      fullName: profile['fullName']?.toString() ?? '',
      email: profile['email']?.toString() ?? '',
      accessToken: token,
      tokenType: 'Bearer',
      shopId: profile['shopId']?.toString() ?? '',
      role: profile['role']?.toString() ?? '',
    );
  }
}
