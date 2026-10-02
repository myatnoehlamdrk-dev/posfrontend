import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent storage for the Sanctum bearer token.
///
/// The token is full account access, so it lives in platform secure storage --
/// the Android Keystore and the iOS Keychain -- rather than in
/// SharedPreferences, which is an unencrypted XML file that any backup, any
/// rooted device, and any `adb` pull can read as plain text.
///
/// Reads are served from an in-memory cache. Secure storage is an async
/// platform-channel round trip, and [AuthInterceptor] asks for the token on
/// every single request; without the cache the interceptor would add a channel
/// hop before each one. The cache is process-local, so it disappears on restart
/// and the next read repopulates it from disk.
class TokenStorage {
  TokenStorage._();

  static const String _key = 'auth_token';

  /// Where the token lived before this migration. Kept only so an existing
  /// install can move its token across on first launch instead of silently
  /// signing every current user out.
  static const String _legacyPrefsKey = 'auth_token';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      // `first_unlock_this_device`: readable by background work once the user
      // has unlocked after a reboot, and -- critically -- excluded from iCloud
      // Keychain sync and from encrypted backups, so the token cannot travel
      // to another device or land in a backup archive.
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static String? _cached;

  /// Set when secure storage could not be used, so [saveToken] does not keep
  /// throwing and the app degrades instead of failing every request.
  static bool _secureStorageUnavailable = false;

  /// Read the bearer token, or null when there is no session.
  static Future<String?> getToken() async {
    if (_cached != null) return _cached;

    if (!_secureStorageUnavailable) {
      try {
        final stored = await _secureStorage.read(key: _key);
        if (stored != null && stored.isNotEmpty) {
          _cached = stored;
          return stored;
        }
      } catch (e) {
        // Keystore desync after a restore, or WebCrypto being unavailable in a
        // non-secure browsing context. Falling through to the plaintext path
        // keeps the app usable; see [_store].
        _secureStorageUnavailable = true;
      }
    }

    // First launch after the upgrade, or the degraded path: move the old
    // plaintext value across, then delete it so the copy in SharedPreferences
    // does not outlive the migration.
    final legacy = await SharedPreferences.getInstance();
    final migrated = legacy.getString(_legacyPrefsKey);

    if (migrated != null && migrated.isNotEmpty) {
      await saveToken(migrated);
    }

    return _cached;
  }

  /// Persist the raw bearer token (without the "Bearer " prefix).
  static Future<void> saveToken(String token) async {
    _cached = token;

    await _store(token);

    // Drop the legacy plaintext copy if one is still around, otherwise the
    // migration in [getToken] would find it again after a cache clear.
    final legacy = await SharedPreferences.getInstance();
    if (legacy.containsKey(_legacyPrefsKey)) {
      await legacy.remove(_legacyPrefsKey);
    }
  }

  /// Write to secure storage, falling back to preferences if it cannot be used.
  ///
  /// The fallback is a platform limitation, not a security decision: on web
  /// the plugin encrypts through `crypto.subtle`, which a non-secure origin
  /// does not expose, so the keystore path is simply unavailable there. It is
  /// logged rather than silent, because a token in preferences on a till is
  /// exactly what this class exists to prevent.
  static Future<void> _store(String token) async {
    if (!_secureStorageUnavailable) {
      try {
        await _secureStorage.write(key: _key, value: token);
        return;
      } catch (e) {
        _secureStorageUnavailable = true;
        debugPrint(
          'TokenStorage: secure storage unavailable, falling back to '
          'SharedPreferences. $e',
        );
      }
    }

    final legacy = await SharedPreferences.getInstance();
    await legacy.setString(_legacyPrefsKey, token);
  }

  /// Remove the stored token (used on logout).
  static Future<void> clearToken() async {
    _cached = null;

    try {
      await _secureStorage.delete(key: _key);
    } catch (e) {
      _secureStorageUnavailable = true;
    }

    final legacy = await SharedPreferences.getInstance();
    await legacy.remove(_legacyPrefsKey);
  }

  /// Drop the in-memory copy without touching disk.
  ///
  /// For tests and for any caller that needs to prove it is reading from
  /// storage rather than from the cache left behind by a previous session.
  @visibleForTesting
  static void resetCache() => _cached = null;
}