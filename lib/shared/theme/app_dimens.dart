/// Corner radii, spacing and icon sizes — the non-colour dimensions.
///
/// These are plain `const` classes rather than a [ThemeExtension]. [AppPalette]
/// has to be an extension because a surface colour is meaningless without
/// knowing the brightness, and a `ThemeExtension` is what lets the framework
/// hand back the right one. None of the values below vary by brightness: a 12dp
/// corner is 12dp in both themes, and a `copyWith`/`lerp` pair that returns the
/// number it was given is dead weight. Read them as constants.
///
/// [AppPalette] holds colour. This file holds size.
library;

import 'package:flutter/material.dart';

/// Corner radius.
///
/// The app had 19 distinct `BorderRadius.circular` values, including `1`, `3`,
/// `5`, `7`, `9`, `11`, `13`, `22`, `24` and three `circular(999)`. Values under
/// 4 are below the point where a radius reads as a radius at all — they just
/// make the corner look slightly soft, which is what most of them were doing by
/// accident.
///
/// `12` and `16` are both kept on purpose. That is not the old inconsistency
/// coming back: `16` is the card radius and `12` is the control radius, and a
/// card should read as a slightly softer object than the button sitting on it.
/// Inputs that were `10` now use `12`, so every text field in the app shares one
/// shape with the login and shop forms.
abstract final class AppRadius {
  const AppRadius._();

  /// Chips, tags, small toggles, badges.
  static const double xs = 4;

  /// Inputs, small buttons, dropdowns.
  static const double sm = 8;

  /// The default control radius: inputs, buttons, list tiles.
  static const double md = 12;

  /// Cards and sheets — the container radius, one step softer than a control.
  static const double lg = 16;

  /// Dialogs, sheets, the shop image well.
  static const double xl = 20;

  /// Fully rounded. Use [StadiumShape] or a [BorderRadius] of this size, never
  /// `999` — `circular(999)` silently clamps to half the shorter side, so it
  /// means something different in a 40dp chip and a 200dp sheet.
  static const double pill = 999;
}

/// Spacing, on Material's 4dp scale.
///
/// The codebase was already close to a 2pt grid — `2`, `6`, `10` and `14` all
/// appeared — so adopting the 4dp scale does collapse about 250 call sites. That
/// is the point: the alternative is a 13-value scale that barely improves on the
/// 19 values it replaced. A `6` gap becoming `4` or `8` changes the density of
/// a screen by a pixel or two, which is far cheaper than maintaining a scale
/// nobody can hold in their head.
///
/// Named by size rather than by role (`s16`, not `medium`) because the number is
/// the thing you need at the call site, and a name like `medium` is ambiguous
/// between padding and gaps.
abstract final class AppSpacing {
  const AppSpacing._();

  /// Hairline separation. The smallest gap the scale offers.
  static const double s4 = 4;

  /// Between related items: icon and its label, chips in a row.
  static const double s8 = 8;

  /// Default gap between siblings in a list or a form row.
  static const double s12 = 12;

  /// Default padding inside a control.
  static const double s16 = 16;

  /// Card padding.
  static const double s20 = 20;

  /// Page gutter. Note the pages disagreed here: settings used 24, profile and
  /// shop used 20. They now share one value.
  static const double s24 = 24;

  /// Between cards in a scrolling page.
  static const double s28 = 28;

  /// Section rhythm.
  static const double s32 = 32;

  /// Section rhythm, large.
  static const double s36 = 36;

  /// Page top padding below a top bar.
  static const double s40 = 40;

  /// Above a footer or an empty-state block.
  static const double s48 = 48;
}

/// Icon sizes.
///
/// 26 distinct `size:` values were in use, from 9 to 84. The display sizes above
/// [xxl] are deliberately not here: an 80px illustration or empty-state glyph is
/// artwork, not a UI icon, and putting it in the scale would imply it is a peer
/// of the 16–32 range.
abstract final class AppIconSize {
  const AppIconSize._();

  /// Inline with body text, or inside a dense list row.
  static const double sm = 16;

  /// The default. Icons in buttons, list tiles and form fields.
  static const double md = 20;

  /// Empty states, prominent leading icons.
  static const double lg = 24;

  /// Standalone icons, top-bar actions.
  static const double xl = 32;

  /// Feature icons.
  static const double xxl = 40;
}

/// Minimum interactive size.
///
/// WCAG 2.2 SC 2.5.8 (Target Size Minimum, level AA) asks for 24×24dp. This app
/// aims higher, because it is used one-handed at a till: SC 2.5.5 (Enhanced,
/// level AAA) asks for 44×44, and 48 is the Material minimum and what the
/// platform accessibility settings on Android target. 44 is the floor for
/// controls a finger has to find; 48 is for the primary action on a screen and
/// for anything destructive.
abstract final class AppTapTarget {
  const AppTapTarget._();

  /// Absolute floor. Anything tappable smaller than this is a defect.
  static const double min = 44;

  /// Primary actions, list rows, and anything destructive.
  static const double comfortable = 48;
}
