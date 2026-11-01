import 'package:posfrontend/shared/services/usb_printer_candidate.dart';
import 'package:posfrontend/shared/services/usb_printer_transport_io.dart'
    if (dart.library.js_interop) 'package:posfrontend/shared/services/usb_printer_transport_web.dart'
    as impl;

/// Sends ESC/POS receipt bytes to a thermal printer over **WebUSB** — the
/// browser's only direct thermal path, for printers on a USB cable.
///
/// The platform split behind the import keeps the native build compiling:
/// WebUSB is a browser API, so the io implementation reports
/// [isSupported] false and the print-settings sheet hides the USB option
/// there (Bluetooth and Wi-Fi already cover native).
abstract final class UsbPrinterTransport {
  /// Whether this platform exposes WebUSB (Chromium, secure context).
  static bool get isSupported => impl.isSupported;

  /// Opens the browser's device chooser. Must be called from a user gesture
  /// (button tap); remembers the choice for later sales.
  static Future<UsbPrinterCandidate> requestDevice() => impl.requestDevice();

  /// The remembered printer, re-resolved against permitted devices — or
  /// null if the operator has never chosen one.
  static Future<UsbPrinterCandidate?> loadSelected() => impl.loadSelected();

  static Future<void> saveSelected(UsbPrinterCandidate device) =>
      impl.saveSelected(device);

  static Future<void> clearSelected() => impl.clearSelected();

  /// Streams [bytes] to the saved printer. Throws [PrintOutputException]
  /// with an operator-facing message when anything in the chain fails.
  static Future<void> send({required List<int> bytes}) =>
      impl.send(bytes: bytes);
}
