import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:posfrontend/shared/l10n/app_language.dart';

/// Holds the active [Locale] for the whole app.
///
/// Modelled directly on [ThemeModeNotifier] for the same reasons: the locale
/// has to be readable synchronously from `main()` and from above the
/// navigator, and mirrored to [SharedPreferences] so the very first frame is
/// already correct instead of flashing English and then re-rendering in the
/// user's language after the settings API answers.
///
/// The local mirror is authoritative at launch. The server copy is written
/// when the user changes the language in Settings, and read back on login to
/// reconcile a device that syncs across installs.
class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier._() : super(AppLanguage.myanmar.locale);

  static final LocaleNotifier instance = LocaleNotifier._();

  static const String _prefsKey = 'pos_locale';

  AppLanguage get language => AppLanguage.fromLocale(value);

  /// Apply the persisted value. Call before `runApp`.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      instance.value = AppLanguage.fromServer(
        prefs.getString(_prefsKey),
      ).locale;
    } catch (_) {
      // A missing preference must not block startup; the enum's default stands.
      instance.value = AppLanguage.myanmar.locale;
    }
  }

  void setLanguage(AppLanguage language) {
    if (value == language.locale) return;
    value = language.locale;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_prefsKey, language.serverValue))
        // Nothing useful to do if the mirror fails: the server write in
        // SettingsViewModel is what actually persists the choice.
        .ignore();
  }
}

/// Mirrors the platform's own list of locales, used only as a fallback when
/// the system language is one we do not ship.
List<Locale> get supportedAppLocales =>
    AppLanguage.values.map((language) => language.locale).toList();

/// Best-effort match of the device language against the shipped set.
AppLanguage? deviceLanguage() {
  final code = PlatformDispatcher.instance.locale.languageCode;
  for (final language in AppLanguage.values) {
    if (language.code == code) return language;
  }
  return null;
}
