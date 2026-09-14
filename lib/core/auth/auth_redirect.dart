import 'package:flutter/material.dart';
import 'package:posfrontend/core/auth/token_storage.dart';

/// Global navigator key — used for auth redirects without BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Redirect to login screen and clear token.
Future<void> redirectToLogin() async {
  await TokenStorage.clearToken();
  if (navigatorKey.currentContext != null) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}
