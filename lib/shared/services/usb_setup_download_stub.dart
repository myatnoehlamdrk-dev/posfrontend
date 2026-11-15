import 'package:url_launcher/url_launcher.dart';

/// Non-web stub: the driver package is a Windows-only installer served from
/// the web build's `web/` directory, so off-web the only sane action is to
/// hand the URL to the OS. The button that triggers this is hidden off-web
/// anyway; this is the fallback if it is still reachable.
abstract final class UsbSetupDownload {
  UsbSetupDownload._();

  /// The asset's name inside `web/`, and the URL path it is served under.
  static const fileName = 'usb-printer-setup.zip';

  /// The download URL for this deployment.
  static Uri get fileUri =>
      Uri.parse('${Uri.base.origin}/usb-printer-setup.zip');

  /// Starts the download via `url_launcher`. Returns false on failure.
  static Future<bool> open() async {
    try {
      return await launchUrl(fileUri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }
}
