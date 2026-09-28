import 'package:flutter/material.dart';

/// Brightness-dependent design tokens.
///
/// Accent colours (brand purple, teal, status hues) live in [AppColors] and are
/// intentionally constant across themes. Everything that describes a *surface*
/// or *text on a surface* belongs here, because those are the only things that
/// must change between light and dark.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.scaffoldBg,
    required this.surface,
    required this.surfaceAlt,
    required this.chipBg,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.selectionTint,
    required this.primary,
    required this.primaryDark,
    required this.cardShadow,
    required this.successBg,
    required this.successFg,
    required this.warningBg,
    required this.warningFg,
    required this.dangerBg,
    required this.dangerFg,
  });

  // Surfaces
  final Color scaffoldBg;
  final Color surface;
  final Color surfaceAlt;
  final Color chipBg;

  // Lines
  final Color border;
  final Color borderStrong;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Tinted selection state (replaces the hardcoded #F5F0FF)
  final Color selectionTint;

  // Brand accent, brightened in dark so CTAs keep their contrast
  final Color primary;
  final Color primaryDark;

  // Card elevation. Zero in dark: separation comes from the border instead,
  // which is both cheaper to paint and more legible on a dark surface.
  final Color cardShadow;

  // Status pairs
  final Color successBg;
  final Color successFg;
  final Color warningBg;
  final Color warningFg;
  final Color dangerBg;
  final Color dangerFg;

  static const AppPalette light = AppPalette(
    scaffoldBg: Color(0xFFF8F9FC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF9FAFB),
    chipBg: Color(0xFFF3F4F6),
    border: Color(0xFFE5E7EB),
    borderStrong: Color(0xFFD1D5DB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    selectionTint: Color(0xFFF5F0FF),
    primary: Color(0xFF7B2CBF),
    primaryDark: Color(0xFF5B21B6),
    cardShadow: Color(0x0D000000),
    successBg: Color(0xFFDCFCE7),
    successFg: Color(0xFF15803D),
    warningBg: Color(0xFFFEF3C7),
    warningFg: Color(0xFFB45309),
    dangerBg: Color(0xFFFEE2E2),
    dangerFg: Color(0xFFB91C1C),
  );

  static const AppPalette dark = AppPalette(
    scaffoldBg: Color(0xFF0E1014),
    surface: Color(0xFF171A20),
    surfaceAlt: Color(0xFF1E222A),
    chipBg: Color(0xFF262B34),
    border: Color(0xFF2C323C),
    borderStrong: Color(0xFF3C434F),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFA2AAB8),
    textMuted: Color(0xFF6C7482),
    selectionTint: Color(0xFF261C40),
    primary: Color(0xFF9D4EDD),
    primaryDark: Color(0xFF7B2CBF),
    cardShadow: Color(0x00000000),
    successBg: Color(0xFF13301F),
    successFg: Color(0xFF6EE7A8),
    warningBg: Color(0xFF302710),
    warningFg: Color(0xFFFCD34D),
    dangerBg: Color(0xFF35191B),
    dangerFg: Color(0xFFFCA5A5),
  );

  /// Standard card treatment: surface fill, hairline border, theme-aware shadow.
  List<BoxShadow> get cardElevation => [
    BoxShadow(
      color: cardShadow,
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  @override
  AppPalette copyWith({
    Color? scaffoldBg,
    Color? surface,
    Color? surfaceAlt,
    Color? chipBg,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? selectionTint,
    Color? primary,
    Color? primaryDark,
    Color? cardShadow,
    Color? successBg,
    Color? successFg,
    Color? warningBg,
    Color? warningFg,
    Color? dangerBg,
    Color? dangerFg,
  }) {
    return AppPalette(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      chipBg: chipBg ?? this.chipBg,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      selectionTint: selectionTint ?? this.selectionTint,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      cardShadow: cardShadow ?? this.cardShadow,
      successBg: successBg ?? this.successBg,
      successFg: successFg ?? this.successFg,
      warningBg: warningBg ?? this.warningBg,
      warningFg: warningFg ?? this.warningFg,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerFg: dangerFg ?? this.dangerFg,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      scaffoldBg: c(scaffoldBg, other.scaffoldBg),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      chipBg: c(chipBg, other.chipBg),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      selectionTint: c(selectionTint, other.selectionTint),
      primary: c(primary, other.primary),
      primaryDark: c(primaryDark, other.primaryDark),
      cardShadow: c(cardShadow, other.cardShadow),
      successBg: c(successBg, other.successBg),
      successFg: c(successFg, other.successFg),
      warningBg: c(warningBg, other.warningBg),
      warningFg: c(warningFg, other.warningFg),
      dangerBg: c(dangerBg, other.dangerBg),
      dangerFg: c(dangerFg, other.dangerFg),
    );
  }
}
