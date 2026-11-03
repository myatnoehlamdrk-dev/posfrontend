import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'package:url_launcher/url_launcher.dart';

/// Where the one-time Windows driver package for the WebUSB thermal printer
/// can be fetched from inside the app.
///
/// The zip ships *with* the web build (`web/usb-printer-setup.zip`), so it is
/// resolved against the page's own origin rather than a hard-coded host: the
/// button keeps working wherever the app is deployed, including local
/// dev servers and sub-path hosting.
class UsbSetupDownload {
  UsbSetupDownload._();

  /// The asset's name inside `web/`, and the URL path it is served under.
  static const fileName = 'usb-printer-setup.zip';

  /// The download URL for this deployment.
  ///
  /// [Uri.base] carries the hash-route fragment, which must not leak into the
  /// file path, so only the leaf of the path is replaced while the scheme,
  /// host and any hosting sub-path are kept.
  static Uri get fileUri {
    final base = Uri.base;
    final path = base.path;
    final cut = path.lastIndexOf('/');
    final dir = cut < 0 ? '/' : path.substring(0, cut + 1);
    return Uri.parse('${base.origin}$dir$fileName');
  }

  /// Starts the download.
  ///
  /// On the web we drive an `<a download>` click through JS, which is far
  /// more reliable than [launchUrl] for binary assets (popup blockers and
  /// MIME handling often make [launchUrl] report failure even when the file
  /// is served). Falls back to [launchUrl] if the JS path throws.
  ///
  /// Returns false when neither path could start the download, so the caller
  /// can say so instead of failing silently.
  static Future<bool> open() async {
    if (kIsWeb) {
      try {
        _downloadViaAnchor(fileUri.toString());
        return true;
      } catch (_) {
        // Fall through to url_launcher.
      }
    }
    try {
      return await launchUrl(fileUri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }
}

@JS('eval')
external void _eval(String code);

void _downloadViaAnchor(String href) {
  // Build the anchor in JS so we do not need a dart:html import (which
  // would not compile on the native targets this file is also part of).
  final safe = href.replaceAll("'", r"\'");
  _eval(
    "var a=document.createElement('a');"
    "a.href='$safe';"
    "a.download='usb-printer-setup.zip';"
    "a.rel='noopener';"
    "document.body.appendChild(a);"
    "a.click();"
    "document.body.removeChild(a);",
  );
}
