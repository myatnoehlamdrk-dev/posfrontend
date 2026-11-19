import 'package:url_launcher/url_launcher.dart';

/// Opens the animated demo page in a new browser tab.
///
/// The page is served next to the Flutter web app from
/// `web/demo/animate.html`, so a relative URL keeps working whether the app is
/// running under `flutter run` or from a build.
Future<bool> openAnimatedDemo() async {
  final uri = Uri.base.resolve('demo/animate.html');
  try {
    return await launchUrl(uri, webOnlyWindowName: '_blank');
  } catch (_) {
    return false;
  }
}
