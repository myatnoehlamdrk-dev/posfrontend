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

  /// A longer, weightier take on [auth] for auth-flow steps that should read as
  /// moving *forward*: login → forgot password, and the back half of the reset
  /// branch.
  ///
  /// [auth] only fades and settles from 0.98, which is almost imperceptible at
  /// arm's length on a till. This adds a short forward travel — the page arrives
  /// from slightly right of and below centre — plus a deeper scale, so the
  /// hand-off reads as moving *forward* to a new step rather than as a texture
  /// cross-fade. The travel stays under 6% of the width because both screens
  /// paint the same radial bloom; anything larger would drag that background.
  ///
  /// The expo-out curve is the smoothness: most of the distance is covered
  /// early and the last few pixels settle slowly, which is what makes the stop
  /// feel soft instead of abrupt.
  ///
  /// The sign-up steps use [authRegister], which is this same motion held
  /// longer on the way in.
  static Route<T> authSmooth<T>(Widget page) {
    return _authPage<T>(page, const Duration(milliseconds: 520));
  }

  /// The sign-up hand-off: the same motion as [authSmooth], held longer on the
  /// way in.
  ///
  /// This is the one step in the auth chain that moves the user from "I have no
  /// account" to "I am creating one", so it gets a slower entrance than the
  /// reset-password branch — long enough that the change of stage registers
  /// instead of flashing past. Only the forward duration changes: the reverse
  /// is a correction and keeps the shared exit timing.
  static Route<T> authRegister<T>(Widget page) {
    return _authPage<T>(page, const Duration(milliseconds: 760));
  }

  /// Shared body for [authSmooth] and [authRegister]; only the entrance
  /// duration varies, so the two can never drift apart in curve or travel.
  static Route<T> _authPage<T>(Widget page, Duration forward) {
    return _AuthPageRoute<T>(page, forward);
  }
}

/// The route behind [AppPageTransitions.authSmooth] and
/// [AppPageTransitions.authRegister].
///
/// Identical to a [PageRouteBuilder] apart from one thing: its controller opts
/// out of Flutter's reduce-motion duration compression.
///
/// When the device reports `AccessibilityFeatures.disableAnimations`, Flutter
/// runs a normal controller at 5% of its length — a 760ms hand-off finishes in
/// roughly 38ms, which reads as an instant swap rather than a transition. Auth
/// steps are navigation, not decoration: losing the motion loses the cue that
/// the flow moved forward. The decorative animations *inside* the screens keep
/// honouring the setting; only the page change is preserved.
class _AuthPageRoute<T> extends PageRouteBuilder<T> {
  _AuthPageRoute(Widget page, Duration forward)
    : super(
        pageBuilder: (_, _, _) => page,
        transitionDuration: forward,
        reverseTransitionDuration: const Duration(milliseconds: 420),
        transitionsBuilder: _authTransition,
      );

  @override
  AnimationController createAnimationController() {
    return AnimationController(
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
      debugLabel: debugLabel,
      vsync: navigator!,
      animationBehavior: AnimationBehavior.preserve,
    );
  }
}

/// Fade, a short forward travel and a settle from 0.97, shared by both auth
/// routes.
Widget _authTransition(
  BuildContext _,
  Animation<double> animation,
  Animation<double> _,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: const Cubic(0.16, 1.0, 0.30, 1.0),
    reverseCurve: Curves.easeInCubic,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.06, 0.015),
        end: Offset.zero,
      ).animate(curved),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
        child: child,
      ),
    ),
  );
}
