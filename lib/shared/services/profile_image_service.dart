import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

/// Keeps the shared avatar URL populated for the whole app.
///
/// The avatar in the app bar, the screen top bar and the drawer all read
/// [ProfileImageNotifier], which is a plain in-memory value starting at `''`.
/// Before this, the *only* things that ever wrote a real URL were the dashboard
/// (on `initState`) and the profile screen (after a load or an upload). So:
///
///  * opening any screen without visiting the dashboard first left the avatar
///    blank on every surface — nothing had fetched it, and
///  * the widgets used to erase the value on a failed render, and with nothing
///    left to refetch it the avatar stayed blank "forever".
///
/// Seeding centrally instead means the avatar no longer depends on which screen
/// the user happens to open. The value is mirrored to local storage so a cold
/// start paints the last known photo immediately rather than showing the
/// fallback glyph until the network answers.
class ProfileImageService {
  static const _prefsKey = 'profile_image_url';

  /// Restores the last known avatar, then refreshes it from the API.
  ///
  /// The restore is deliberate and separate from the refresh: a shop on a slow
  /// or dead connection would otherwise show initials on every launch even
  /// though the photo is already cached on disk.
  static Future<void> warmUp() async {
    await _restoreCached();

    // Only attempt the network call when there is a session to authenticate
    // with; without a token this would 401 on every cold start of a signed-out
    // app.
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final resp = await ApiClient.instance.get('/auth/profile');
      final data = resp.data;
      final image = (data is Map<String, dynamic>) ? data['image'] : null;
      if (image is! String || image.isEmpty) return;

      final resolved = resolveMediaUrl(image) ?? image;
      ProfileImageNotifier.instance.update(resolved);
      await _remember(resolved);
    } catch (e) {
      // Non-critical: the avatar falls back to initials, and the next launch
      // or the profile screen retries. Never let this break startup.
      debugPrint('Profile image warm-up failed: $e');
    }
  }

  /// Records a freshly uploaded avatar so the other surfaces pick it up.
  static Future<void> remember(String url) async {
    final resolved = resolveMediaUrl(url) ?? url;
    ProfileImageNotifier.instance.update(resolved);
    await _remember(resolved);
  }

  static Future<void> _restoreCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefsKey);
      if (cached == null || cached.isEmpty) return;
      ProfileImageNotifier.instance.update(cached);
    } catch (_) {
      // A failed read only costs the head start, not correctness.
    }
  }

  static Future<void> _remember(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, url);
    } catch (_) {
      // Cache write failure is harmless; the notifier already holds the value.
    }
  }

  /// Clears the avatar, for sign-out.
  ///
  /// Called from the sign-out path so one user's photo is not left on screen —
  /// or restored on the next cold start — for whoever signs in next.
  static Future<void> clear() async {
    ProfileImageNotifier.instance.update('');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}
