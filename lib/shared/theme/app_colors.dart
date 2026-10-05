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

  // Brand purple ramp — one hue, 257°, six steps.
  //
  // This ramp is the only place a purple may be defined. It replaced eleven
  // near-miss violets that had drifted across 23° of hue and 45.8–94.7%
  // saturation, which is why the same control looked like it belonged to two
  // different apps depending on which screen you were on. The anchor is
  // [brandPurple]: it is the colour the welcome screen's `Get started` button
  // is already painted in, so the app's most-used control now matches the first
  // screen that sets the brand impression.
  static const Color brandPurpleDarker = Color(0xFF5A3DA4); // 700
  static const Color brandPurpleDark = Color(0xFF6D28D9); // 600
  static const Color brandPurple = Color(0xFF7952DB); // 500 — the anchor
  static const Color violet400 = Color(0xFF8B5CF6); // 400
  static const Color violet300 = Color(0xFFA78BFA); // 300
  static const Color lavender = Color(0xFFC4B5FD); // 200

  /// Every step above clears 4.5:1 against white text, so a label is legible on
  /// any stop of a gradient built from this ramp:
  ///
  ///   700 7.96 · 600 7.10 · 500 5.19 · 400 4.23 · 300 2.72 · 200 1.79
  ///
  /// Only 700–500 are safe for white text. 400 and lighter are tint steps: use
  /// them for artwork, hover tints, and accent *text* on a dark surface (where
  /// [violet300] reaches 4.84:1) — never as a fill under white text.
  ///
  /// Accessory role, not decorative — a hover state or a pressed fill. One step
  /// darker than [brandPurple], same hue.
  static const Color brandPurpleHover = brandPurpleDark;

  @Deprecated(
    'Use AppColors.brandPurple. Kept only so the rename can land in one pass.',
  )
  static const Color primary = brandPurpleDark;

  @Deprecated(
    'Use AppColors.violet400. Kept only so the rename can land in one pass.',
  )
  static const Color primaryLight = violet400;

  @Deprecated(
    'Use AppColors.brandPurpleDarker. Kept only so the rename can land in one pass.',
  )
  static const Color primaryDark = brandPurpleDarker;

  @Deprecated(
    'Use AppColors.brandPurpleDark. Kept only so the rename can land in one pass.',
  )
  static const Color purple = brandPurpleDark;

  @Deprecated(
    'Use AppColors.brandPurple. Kept only so the rename can land in one pass.',
  )
  static const Color purple700 = brandPurple;

  @Deprecated(
    'Use AppColors.violet400. Kept only so the rename can land in one pass.',
  )
  static const Color lightViolet = violet400;

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

  /// The brand ramp: three steps of the single brand hue, light to dark.
  ///
  /// Shared by the onboarding hero, the login brand pane, the drawer's active
  /// avatar, the image-upload drop zone and the wizard step dots, so a gradient
  /// is recognisably the same gradient wherever it appears rather than each
  /// screen picking its own pair of purples.
  ///
  /// It used to sweep 63° from violet through to sky
  /// (`#7C3AED #8B5CF6 #6366F1 #3B82F6 #0EA5E9`). That is a hue shift, not a
  /// ramp: it put two unrelated hues under one label, and the sky end
  /// (`#0EA5E9`) gives white text only 2.77:1, so anything white sitting on it
  /// failed. All three stops below are the same hue and clear 4.5:1 against
  /// white, so a label stays legible anywhere on the gradient.
  ///
  /// The interactive button deliberately does *not* use this — it is painted
  /// solid [brandPurple]. A gradient on a control adds a second hue to reason
  /// about for no gain, and a five-stop sweep is what made the same button look
  /// different on each screen it appeared on.
  ///
  /// Lives here rather than in the screen that introduced it because a ramp
  /// copied into a second file is a ramp that will drift: someone adds a stop
  /// to the onboarding hero, the login pane keeps the old one, and the two
  /// screens that are supposed to look like one product quietly stop matching.
  ///
  /// Const, not palette-driven, for the same reason as the rest of this class:
  /// these are brand hues used as artwork, not surfaces that need to hold
  /// contrast in both brightnesses.
  static const List<Color> brandRamp = [
    brandPurple,
    brandPurpleDark,
    brandPurpleDarker,
  ];
}
