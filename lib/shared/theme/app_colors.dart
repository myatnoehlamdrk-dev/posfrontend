import 'package:flutter/material.dart';

/// Brand accents, constant across light and dark.
///
/// Anything that describes a *surface* or *text sitting on a surface* used to
/// live here as a `static const` and now lives in [AppPalette], reachable via
/// `context.palette`. A `const` colour cannot vary by brightness, which is why
/// neutrals had to move.
///
/// The values below are safe to keep const because they are brand hues, not
/// surfaces.
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF7B2CBF);
  static const Color primaryLight = Color(0xFF9D4EDD);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color purple = Color(0xFF6D28D9);
  static const Color purple700 = Color(0xFF7C3AED);

  /// The single interactive purple for the product flows: prices, the search
  /// affordance and the welcome screen's `Get started` button are all painted
  /// in this. Kept apart from [purple] and [primary] on purpose — those are the
  /// older violets, and mixing the three on one screen is what made the same
  /// control look like it belonged to two apps.
  static const Color brandPurple = Color(0xFF7952DB);

  /// The dark end of the [brandPurple] ramp, for gradients that need a second
  /// step. It is a shade of the same hue rather than the theme's `primaryDark`:
  /// pairing a brand purple with a different violet is what made the gradient
  /// read as two colours rather than one button.
  static const Color brandPurpleDark = Color(0xFF5A3DA4);

  /// The light violet the welcome screen paints its caption and eyebrow dot in.
  /// Used for the softer accents in the checkout flow, where the control is
  /// supporting rather than the thing being confirmed. Lighter than
  /// [brandPurple] on purpose, so it is a tint and not a second primary —
  /// anything that has to carry meaning at small sizes stays on [brandPurple].
  static const Color lightViolet = Color(0xFF9D7AD6);

  /// The two lighter steps of the violet ramp, used for hover states and for
  /// accent text that has to stay legible on a dark surface. Kept next to
  /// [purple700] so a page assembling a violet ramp picks them from one place
  /// rather than re-deriving the hue from memory.
  static const Color violet400 = Color(0xFF8B5CF6);
  static const Color violet300 = Color(0xFFA78BFA);
  static const Color lavender = Color(0xFFC4B5FD);

  // Teal
  static const Color teal = Color(0xFF14B8A6);
  static const Color tealDark = Color(0xFF0F9D8A);

  // Status accents. For a badge or chip use the palette pairs instead
  // (`palette.successBg` / `palette.successFg`) so the two stay in step.
  static const Color green = Color(0xFF16A34A);
  static const Color orange = Color(0xFFD97706);
  static const Color orangeBright = Color(0xFFF97316);
  static const Color red = Color(0xFFEF4444);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueBright = Color(0xFF2563EB);

  /// The brand ramp: violet through to sky.
  ///
  /// Shared by the onboarding hero, every `GradientButton` and the login brand
  /// pane, so a gradient is recognisably the same gradient wherever it appears
  /// rather than each screen picking its own pair of purples.
  ///
  /// Lives here rather than in the screen that introduced it because a ramp
  /// copied into a second file is a ramp that will drift: someone adds a stop
  /// to the onboarding hero, the login button keeps the old one, and the two
  /// screens that are supposed to look like one product quietly stop matching.
  ///
  /// Const, not palette-driven, for the same reason as the rest of this class:
  /// these are brand hues used as artwork, not surfaces that need to hold
  /// contrast in both brightnesses.
  static const List<Color> brandRamp = [
    Color(0xFF7C3AED),
    Color(0xFF8B5CF6),
    Color(0xFF6366F1),
    Color(0xFF3B82F6),
    Color(0xFF0EA5E9),
  ];
}
