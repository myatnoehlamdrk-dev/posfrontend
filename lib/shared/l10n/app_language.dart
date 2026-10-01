import 'package:flutter/widgets.dart';

/// The languages the UI can be displayed in.
///
/// [serverValue] is the exact string persisted in the `language` field of the
/// settings API. It predates this enum and is stored verbatim in the database,
/// so it must not change — otherwise existing rows stop matching. New code
/// should compare [AppLanguage] rather than the raw string.
///
/// [code] is the ISO-639-1 code used for the [Locale] Flutter switches on.
///
/// [autonym] is the language's name in that language. The picker shows
/// autonyms so a shop owner who cannot read the current UI language can still
/// find their own — which is the whole point of a language picker.
enum AppLanguage {
  myanmar('Myanmar', 'my', 'မြန်မာ'),
  english('English', 'en', 'English'),
  thai('Thai', 'th', 'ไทย'),
  japanese('Japanese', 'ja', '日本語');

  const AppLanguage(this.serverValue, this.code, this.autonym);

  /// Stored in the settings API and in the database. Stable contract.
  final String serverValue;

  /// ISO-639-1, used to build the [Locale].
  final String code;

  /// Name of the language, written in that language.
  final String autonym;

  Locale get locale => Locale(code);

  /// Resolves a persisted `language` value, tolerating anything the database
  /// might already hold.
  ///
  /// Falling back rather than throwing matters here: a bad value would
  /// otherwise take down the whole app at startup, and a wrong language is a
  /// much better outcome than a white screen. Unknown values (including the
  /// retired 'Korean') land on [english], which is the only language every
  /// translation set is guaranteed to be complete in.
  static AppLanguage fromServer(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return AppLanguage.english;
    for (final language in AppLanguage.values) {
      if (language.serverValue.toLowerCase() == value) return language;
      if (language.code == value) return language;
    }
    return AppLanguage.english;
  }

  static AppLanguage fromLocale(Locale locale) {
    for (final language in AppLanguage.values) {
      if (language.code == locale.languageCode) return language;
    }
    return AppLanguage.english;
  }
}
