import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A stable, human-readable label for this installation.
///
/// Sent as `device_name` at login and stored by the API as the Sanctum token
/// name, which is what makes `GET /auth/sessions` answerable: an admin sees
/// `pos-android-4f2a` rather than six sessions all called "mobile", and can
/// revoke the one on a lost handset without signing the user out everywhere.
///
/// Generated once and kept in SharedPreferences, not secure storage -- it is a
/// label, not a secret, and it has to survive a process restart to stay stable.
class TerminalIdentity {
  TerminalIdentity._();

  static const String _key = 'terminal_id';

  /// No vowels and no look-alike characters: this string gets read aloud over a
  /// phone during an incident, and `0`/`o`/`1`/`l` read wrong.
  static const String _alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';

  static String? _cached;

  static Future<String> label() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);

    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }

    final random = Random.secure();
    final suffix = List.generate(
      4,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
    ).join();

    _cached = '${_platform()}-$suffix';
    await prefs.setString(_key, _cached!);

    return _cached!;
  }

  /// [defaultTargetPlatform], not `dart:io`'s `Platform`.
  ///
  /// `dart:io` is not available on web: dart2js substitutes a stub whose
  /// `operatingSystem` throws `Unsupported operation`, so `Platform.isAndroid`
  /// inside a login call took the whole sign-in down with it. This getter is
  /// the web-safe equivalent and resolves to the browser platform there.
  static String _platform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'pos-android';
      case TargetPlatform.iOS:
        return 'pos-ios';
      case TargetPlatform.windows:
        return 'pos-windows';
      case TargetPlatform.macOS:
        return 'pos-macos';
      case TargetPlatform.linux:
        return 'pos-linux';
      case TargetPlatform.fuchsia:
        return 'pos-fuchsia';
    }
  }
}