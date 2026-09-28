import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Theme-token access from a [BuildContext].
///
/// Replaces the old `AppColors.gray` / `AppColors.titleColor` style of access.
/// Those were `static const`, so they could not vary by brightness; reading from
/// the active [ThemeData] is what makes a single codebase serve both themes.
extension PaletteX on BuildContext {
  AppPalette get palette {
    final ext = Theme.of(this).extension<AppPalette>();
    assert(ext != null, 'AppPalette is missing from the active ThemeData.');
    return ext ?? AppPalette.light;
  }

  /// True when the active theme is dark. Use for the rare case where a widget
  /// needs to branch rather than read a token.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
