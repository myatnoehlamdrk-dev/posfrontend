/// The type scale: eleven roles instead of 655 literals.
///
/// The app had 30 distinct `fontSize:` values, 145 text sites below 12dp, 48
/// below 10dp, and not one feature reading a named style off `textTheme` —
/// every screen built its own `TextStyle`. That is why the same heading was a
/// different size on four screens.
///
/// Two things this file deliberately does *not* do.
///
/// It does not set a colour. A text colour depends on brightness and belongs to
/// [AppPalette], so apply it at the call site:
/// `AppTypography.bodyMedium.copyWith(color: p.textPrimary)`. Hard-coding
/// `color:` here would reintroduce exactly the bug Phase 1 fixed, where
/// `#111827` headings were unreadable on a dark surface.
///
/// It does not collapse the dense end. Material 3 offers 12/14/16; this app
/// needed 12/13/14/15/16 because 141 sites sat at 13 and 31 at 15, and moving
/// them all at once would have changed the size of nearly every label in the
/// product. Dense roles stay distinct by pairing size with weight and colour —
/// three preattentive channels — which is what actually separates a 13px label
/// from a 14px body line when they sit next to each other.
library;

import 'package:flutter/material.dart';

/// Named text roles.
///
/// Sizes are plain `const` doubles so a `SizedBox` or a `Row` constraint can
/// read one directly without instantiating a [TextStyle].
abstract final class AppTypography {
  const AppTypography._();

  // Sizes

  /// 12dp. The floor. Supporting metadata, badges, table headers, timestamps.
  static const double labelSmallSize = 12;

  /// 13dp. Dense labels, chart axis labels, secondary button text.
  static const double labelMediumSize = 13;

  /// 14dp. Default body text: form fields, list rows, helper text.
  static const double bodySmallSize = 14;

  /// 15dp. Default body text on a roomy screen.
  static const double bodyMediumSize = 15;

  /// 16dp. Comfortable body text, dialog content.
  static const double bodyLargeSize = 16;

  /// 18dp. Subsection headings.
  static const double titleSmallSize = 18;

  /// 20dp. Card and dialog titles.
  static const double titleMediumSize = 20;

  /// 24dp. Page titles.
  static const double titleLargeSize = 24;

  /// 26dp. Large in-app figures.
  static const double displaySmallSize = 26;

  /// 30dp. KPI values.
  static const double displayMediumSize = 30;

  /// 34dp. Empty-state and login hero figures.
  static const double displayLargeSize = 34;

  // Roles

  /// Metadata that supports a value but is never the value. 12/500.
  ///
  /// Do not use for a price, a quantity or a total: those are [titleMedium] or
  /// larger. At 12dp in `textMuted` this is the least legible role in the app,
  /// which is the point — it should look secondary because it is.
  static const TextStyle labelSmall = TextStyle(
    fontSize: labelSmallSize,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.2,
  );

  /// A label that sits next to data. 13/500.
  static const TextStyle labelMedium = TextStyle(
    fontSize: labelMediumSize,
    fontWeight: FontWeight.w500,
    height: 1.38,
    letterSpacing: 0.1,
  );

  /// The default reading size. 14/400.
  static const TextStyle bodySmall = TextStyle(
    fontSize: bodySmallSize,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  /// Body text where there is room. 15/400.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: bodyMediumSize,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Body text in dialogs and cards. 16/400.
  static const TextStyle bodyLarge = TextStyle(
    fontSize: bodyLargeSize,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Subsection heading. 18/600.
  static const TextStyle titleSmall = TextStyle(
    fontSize: titleSmallSize,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  /// Card, dialog and sheet title. 20/700.
  static const TextStyle titleMedium = TextStyle(
    fontSize: titleMediumSize,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// Page title. 24/700.
  static const TextStyle titleLarge = TextStyle(
    fontSize: titleLargeSize,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// A large figure that is still part of the page. 26/700.
  static const TextStyle displaySmall = TextStyle(
    fontSize: displaySmallSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.2,
  );

  /// A KPI value. 30/700.
  static const TextStyle displayMedium = TextStyle(
    fontSize: displayMediumSize,
    fontWeight: FontWeight.w700,
    height: 1.17,
    letterSpacing: -0.4,
  );

  /// The largest figure in the app. 34/700.
  static const TextStyle displayLarge = TextStyle(
    fontSize: displayLargeSize,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
  );
}
