import 'package:posfrontend/shared/services/bluetooth_printer_candidate.dart';
import 'package:posfrontend/shared/services/thermal_printer_transport_io.dart'
    if (dart.library.js_interop) 'package:posfrontend/shared/services/thermal_printer_transport_web.dart'
    as impl;

/// Sends receipt bytes straight to a thermal printer — Bluetooth or network —
/// with no OS dialog in between.
///
/// The platform split behind the import is what keeps the web build alive:
/// neither `dart:io` sockets nor the Bluetooth plugin exist in a browser, so
/// the web build links a stub that reports [isSupported] false. Callers hide
/// their thermal choices there instead of offering buttons that can only
/// ever fail, leaving PDF as the browser's output.
abstract final class ThermalPrinterTransport {
  /// Whether this platform can send to a thermal printer at all.
  static bool get isSupported => impl.isSupported;

  /// Prints over raw TCP to `host:port` (9100 for virtually every ESC/POS
  /// network printer).
  static Future<void> sendToWifi({
    required String host,
    required int port,
    required List<int> bytes,
  }) => impl.sendToWifi(host: host, port: port, bytes: bytes);

  /// Prints to a paired/bonded Bluetooth printer at [address]. The connection
  /// is kept open afterwards so the next sale prints instantly.
  static Future<void> sendToBluetooth({
    required String address,
    required List<int> bytes,
  }) => impl.sendToBluetooth(address: address, bytes: bytes);

  /// The printers the OS already knows. On Android that means *paired*
  /// devices (pair first in system settings); on iOS it scans nearby for a
  /// few seconds instead, since iOS pairing is initiated per-connection.
  static Future<List<BluetoothPrinterCandidate>> listPaired() =>
      impl.listPaired();
}
