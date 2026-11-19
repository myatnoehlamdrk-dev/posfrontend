import 'package:flutter/widgets.dart';

/// Native builds never embed the demo page: they keep the Flutter Get Started
/// screen and hand the HTML page to the system browser when it is asked for.
///
/// [onGetStarted] is ignored here; it exists so the two implementations share
/// one signature.
Widget buildDemoPageView({required VoidCallback onGetStarted}) {
  return const SizedBox.shrink();
}
