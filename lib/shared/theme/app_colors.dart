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
}
