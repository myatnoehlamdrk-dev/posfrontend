import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:posfrontend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:posfrontend/features/settings/domain/entities/settings.dart';
import 'package:posfrontend/shared/l10n/app_language.dart';
import 'package:posfrontend/shared/l10n/locale_notifier.dart';
import 'package:posfrontend/shared/theme/theme_mode_notifier.dart';

/// Pushes the shop's server-saved theme and language into the app-wide
/// notifiers.
///
/// Shared by [SettingsViewModel.loadSettings] (the Settings screen) and
/// [syncServerPreferences] (session start), so the two can never drift apart:
/// wherever settings arrive from, "the server copy wins" is applied the same
/// way.
void applyServerPreferences(SettingsEntity settings) {
  // A stored "system" predates the removal of the Match System toggle:
  // pin the brightness the OS is showing, then let the server copy take
  // over like any other explicit choice. Without the pin the till would
  // keep following the OS with no control left to change it.
  if (ThemeModeNotifier.instance.value == ThemeMode.system) {
    ThemeModeNotifier.instance.setMode(ThemeModeNotifier.system);
  }
  ThemeModeNotifier.instance.setMode(
    settings.themeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
  );
  // Same reasoning for language: a shop that syncs settings across devices
  // should open in the language its owner chose elsewhere. Unlike the
  // theme there is no "follow the OS" opt-in, so the server always wins.
  LocaleNotifier.instance.setLanguage(
    AppLanguage.fromServer(settings.language),
  );
}

/// Fetches the shop's saved theme and language from the API and applies them.
///
/// Runs whenever a session starts — a fresh sign-in ([LoginViewModel.login])
/// and a restored session on cold start ([SplashScreen]) alike — so the till
/// opens in the owner's chosen theme and language without anyone having to
/// visit Settings first, which was the only place these were loaded before.
///
/// Best effort by design: every failure (offline, slow server, a token that
/// expired mid-flight) is swallowed, and the call is time-boxed so a login
/// that awaits it can never hang on a settings endpoint. On failure the app
/// simply keeps the locally mirrored copy that painted the first frame, and
/// the Settings screen still applies the server copy whenever it is opened.
Future<void> syncServerPreferences() async {
  try {
    final settings = await SettingsRepositoryImpl()
        .getSettings()
        .timeout(const Duration(seconds: 5));
    applyServerPreferences(settings);
  } catch (e) {
    debugPrint('Server theme/language sync skipped: $e');
  }
}
