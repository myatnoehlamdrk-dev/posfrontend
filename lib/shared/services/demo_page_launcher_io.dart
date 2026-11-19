import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Opens the repo's animated demo page in the platform's default browser.
///
/// Returns false when the page cannot be found or the browser refuses to open
/// it, so the caller can explain instead of failing silently.
Future<bool> openAnimatedDemo() async {
  final page = _findDemoPage();
  if (page == null) return false;
  try {
    return await launchUrl(page.uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Looks for `marketing/site/animate.html` beside the project.
///
/// Both the working directory and the executable are used as starting points,
/// then walked upwards, so the page is found whether the app runs via
/// `flutter run` or from a `build/` output folder.
File? _findDemoPage() {
  const page = 'marketing/site/animate.html';
  final starts = <String>{
    Directory.current.path,
    File(Platform.resolvedExecutable).parent.path,
  };

  for (final start in starts) {
    var dir = Directory(start);
    for (var depth = 0; depth < 8; depth++) {
      for (final relative in [page, '../$page']) {
        final candidate = File(
          [dir.path, ...relative.split('/')].join(Platform.pathSeparator),
        );
        if (candidate.existsSync()) return candidate;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
  }
  return null;
}
