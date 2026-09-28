import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active [ThemeMode] for the whole app.
///
/// Modelled as a `ValueNotifier` singleton after `CartStore.instance`
/// (`features/cart/data/cart_store.dart`) because the mode has to be readable
/// synchronously from `main()` and from above the navigator — neither is
/// possible with a screen-scoped ViewModel.
///
/// The value is mirrored to [SharedPreferences] so the theme is correct on the
/// very first frame. Without that, the per-user server setting would only
/// arrive after the API round-trip and the app would flash light before going
/// dark. The mirror is authoritative at launch; the server refreshes it after.
class ThemeModeNotifier extends ValueNotifier<ThemeMode> {
  ThemeModeNotifier._() : super(ThemeMode.light);

  static final ThemeModeNotifier instance = ThemeModeNotifier._();

  static const String _prefsKey = 'pos_theme_mode';

  /// Apply the persisted value. Call before `runApp` so the first frame is
  /// already correct.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      instance.value = _decode(stored);
    } catch (_) {
      // A theme is cosmetic; fall back to light rather than failing startup.
      instance.value = ThemeMode.light;
    }
  }

  /// Resolve the system preference. Used when the user has never chosen, and
  /// by 'follow system'.
  static ThemeMode get system => switch (PlatformDispatcher.instance.platformBrightness) {
        Brightness.dark => ThemeMode.dark,
        Brightness.light => ThemeMode.light,
      };

  static ThemeMode _decode(String? raw) => switch (raw) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
      };

  void setMode(ThemeMode mode) {
    if (value == mode) return;
    value = mode;
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _encode(value));
    } catch (_) {
      // Non-critical: the server copy is the real source of truth.
    }
  }
}
