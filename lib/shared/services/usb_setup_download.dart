import 'usb_setup_download_stub.dart'
    if (dart.library.js_interop) 'usb_setup_download_web.dart' as impl;

/// Where the one-time Windows driver package for the WebUSB thermal printer
/// can be fetched from inside the app.
///
/// The platform split behind the import keeps the native build compiling: the
/// web implementation drives an `<a download>` click through JS, while the
/// native stub serves the URL via `url_launcher` and lets the OS handle it.
abstract final class UsbSetupDownload {
  /// The asset's name inside `web/`, and the URL path it is served under.
  static const fileName = impl.UsbSetupDownload.fileName;

  /// The download URL for this deployment.
  static Uri get fileUri => impl.UsbSetupDownload.fileUri;

  /// Starts the download. Returns false when it could not be started.
  static Future<bool> open() => impl.UsbSetupDownload.open();
}
