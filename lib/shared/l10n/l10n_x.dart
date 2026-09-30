import 'package:flutter/widgets.dart';
import 'package:posfrontend/shared/l10n/app_strings.dart';

/// `context.l10n` for translations, following the `context.palette` idiom
/// already used throughout the app.
///
/// Only available where there is a [BuildContext]. ViewModels, repositories
/// and services have none, which is why [AppStrings] is keyed by English text
/// and applied at the point of display — see the notes on that class.
extension L10nX on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}
