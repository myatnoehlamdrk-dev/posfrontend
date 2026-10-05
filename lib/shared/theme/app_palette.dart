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
    required this.accentText,
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

  /// Brand accent for *fills*: buttons, chips, avatars, the refresh spinner.
  ///
  /// Same value in both modes on purpose. It used to be `#7B2CBF` light and a
  /// brightened `#9D4EDD` dark, because a fill was assumed to need headroom in
  /// dark. It does not — the label on top is white, and white clears 4.5:1
  /// against this value in both brightnesses (5.19). Brightening it only made
  /// the button read as a different colour from the one on the login screen.
  final Color primary;

  /// Pressed / hover fill. One step down the same hue.
  final Color primaryDark;

  /// Brand accent for *text and icons*, which is a different job from [primary]
  /// and needs a different value.
  ///
  /// This exists because one token was doing both jobs and failing one of them.
  /// The fill job wants white text on top, so it needs a mid-dark purple. The
  /// text job needs contrast against the *page*, and on a dark surface the same
  /// purple only reaches 2.54:1 — so accent-coloured text was unreadable in
  /// dark mode while the button it sat next to was fine.
  ///
  /// Measured against every surface it is actually painted on:
  ///
  ///   light  5.19 on surface · 4.72 on chipBg · 4.65 on selectionTint
  ///   dark   4.84 on surface · 5.83 on selectionTint · 3.75 on chipBg
  ///
  /// The dark `chipBg` figure is 3.75, below 4.5, and that is acceptable: the
  /// only control painted on `chipBg` is an *icon*, and WCAG 1.4.11 governs
  /// non-text content at 3:1, not 4.5:1. If a text label is ever put on the
  /// dark `chipBg`, it needs a lighter step (`lavender`), not this one.
  final Color accentText;

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

  /// The three text steps are a ramp, not independent picks, and all three clear
  /// 4.5:1 against every light surface they sit on:
  ///
  ///   textPrimary 14.03 · textSecondary 6.51 · textMuted 5.19  (on scaffoldBg)
  ///   textPrimary 12.29 · textSecondary 5.79 · textMuted 4.81  (on surfaceAlt)
  ///
  /// `textMuted` used to be `#9CA3AF`, which is only 2.41:1 on `scaffoldBg` —
  /// the third step down was failing the same bar as the second one. Darkening
  /// it to 4.5+ meant pulling `textSecondary` up to `#5A6373` so the two stayed
  /// visibly distinct instead of collapsing into one grey. The cost is that
  /// `textMuted` is now only slightly lighter than `textSecondary`; in light
  /// mode there is very little room below 4.5:1, so a third step has to be a
  /// small one. Use `textMuted` for supporting metadata, never for a value the
  /// user has to read to complete a sale.
  ///
  /// `borderStrong` clears 3:1 against `surface` (3.25) because it is painted on
  /// component outlines — the outlined buttons in `cart_actions`, the selection
  /// borders in `category_products` — which are UI components under WCAG 1.4.11
  /// rather than decoration. It was 1.47:1 before.
  ///
  /// [border] is *not* held to 3:1 and deliberately stays a hairline: it draws
  /// dividers and card edges, which carry no information on their own. Note
  /// that `appInputDecoration` also uses it for input outlines, which *are*
  /// components — see the note on that widget.
  static const AppPalette light = AppPalette(
    scaffoldBg: Color(0xFFF8F9FC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF9FAFB),
    chipBg: Color(0xFFF3F4F6),
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF5A6373),
    textMuted: Color(0xFF6A7078),
    selectionTint: Color(0xFFF5F0FF),
    primary: Color(0xFF7952DB),
    primaryDark: Color(0xFF6D28D9),
    accentText: Color(0xFF7952DB),
    borderStrong: Color(0xFF8A8F98),
    cardShadow: Color(0x0D000000),
    successBg: Color(0xFFDCFCE7),
    successFg: Color(0xFF15803D),
    warningBg: Color(0xFFFEF3C7),
    warningFg: Color(0xFFB45309),
    dangerBg: Color(0xFFFEE2E2),
    dangerFg: Color(0xFFB91C1C),
  );

  /// The neutrals below are a ramp, not a set of independent choices.
  ///
  /// `scaffoldBg` is the page and every other neutral steps *up* from it, which
  /// is what keeps a card reading as a surface sitting above the page rather
  /// than a hole punched into it. The old base was `#0E1014`, which forced the
  /// ramp down into near-black and made a full screen of it genuinely tiring to
  /// work under all day. `#1D2733` keeps the same blue-grey character at a
  /// weight a tiller can stare at for a shift, and the steps between the tokens
  /// are unchanged from the old ramp, so the contrast relationships survive
  /// intact.
  ///
  /// If `scaffoldBg` changes again, the rest of these have to move with it.
  static const AppPalette dark = AppPalette(
    scaffoldBg: Color(0xFF1D2733),
    surface: Color(0xFF26313F),
    surfaceAlt: Color(0xFF2D3949),
    chipBg: Color(0xFF354253),
    border: Color(0xFF3B495B),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFA2AAB8),
    textMuted: Color(0xFF9BA4B3),
    selectionTint: Color(0xFF261C40),
    primary: Color(0xFF7952DB),
    primaryDark: Color(0xFF6D28D9),
    accentText: Color(0xFFA78BFA),
    borderStrong: Color(0xFF70809A),
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
    BoxShadow(color: cardShadow, blurRadius: 10, offset: const Offset(0, 2)),
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
    Color? accentText,
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
      accentText: accentText ?? this.accentText,
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
      accentText: c(accentText, other.accentText),
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
