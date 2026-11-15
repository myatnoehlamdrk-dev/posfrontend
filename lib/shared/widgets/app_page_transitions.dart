import 'package:flutter/material.dart';

/// Standard page transitions for the app.
///
/// Centralises motion so every pushed screen animates the same way instead of
/// each call site picking its own `MaterialPageRoute`. Phase 4 ("Modern
/// refresh") standardises on a short fade + slight upward slide for normal
/// navigation and a fade for modal sheets.
class AppPageTransitions {
  AppPageTransitions._();

  /// Pushes [page] with the standard fade + slide-up transition.
  static Route<T> fadeSlide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Pushes [page] with a pure fade — used for full-screen replacements
  /// (splash → home, login → dashboard) where a slide would imply hierarchy.
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
          child: child,
        );
      },
    );
  }

  /// Fade-through for the auth and onboarding flow (login → forgot password,
  /// login → create shop, create shop → register).
  ///
  /// Those screens all paint the same radial bloom behind their layouts, so
  /// [fadeSlide] would drag that shared background sideways and make the two
  /// pages look like they are sliding over a photograph. A cross-fade keeps the
  /// background still; the small 0.98 → 1.0 scale on the incoming page gives it
  /// a sense of settling into place, which a flat [fade] between two different
  /// forms does not.
  static Route<T> auth<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
