import 'package:flutter/material.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/features/auth/presentation/screens/login_screen.dart';

/// Global navigator key — used for auth redirects without BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Guard against stacked redirects.
///
/// A screen that fires several requests at once gets a 401 on all of them, and
/// each one would otherwise navigate. The first clears the stack; the rest
/// would each push a further login route on top of it, so the tiller watches
/// the login screen rebuild itself under their thumb while holding the phone.
/// Set while a redirect is in flight and cleared once the login screen is up.
bool _redirecting = false;

/// Send the user back to login, clearing the session.
///
/// Pushes [LoginScreen] directly rather than a named route. `MaterialApp` in
/// `main.dart` declares no `routes` and no `onGenerateRoute`, so a
/// `pushNamedAndRemoveUntil('/login')` here would throw at the first expired
/// token — the exact moment the app most needs to keep working. The trade-off
/// is that this file now imports a screen, which is what a global redirect
/// without a router forces.
Future<void> redirectToLogin() async {
  if (_redirecting) return;
  _redirecting = true;

  await TokenStorage.clearToken();
  // The cached profile goes with the token. Leaving it behind would let the
  // next launch restore a session the server had just rejected — and with a
  // user id that no longer belongs to this token.
  await SessionStore.clear();

  final navigator = navigatorKey.currentState;
  if (navigator == null) {
    // Before the first frame there is nothing to navigate; the app will open
    // on its normal start-up path anyway.
    _redirecting = false;
    return;
  }

  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// Re-arms the redirect guard. Called once the user has a session again,
/// otherwise every later 401 in the app's life would be silently swallowed.
void resetLoginRedirect() => _redirecting = false;