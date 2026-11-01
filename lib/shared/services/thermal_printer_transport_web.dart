import 'package:posfrontend/shared/services/bluetooth_printer_candidate.dart';
import 'package:posfrontend/shared/services/print_output_exception.dart';

/// The browser stub: no raw sockets, no classic Bluetooth.
///
/// Browsers expose neither a TCP client nor the SPP profile thermal printers
/// speak (Web Bluetooth is BLE-only), so there is nothing honest to
/// implement. [isSupported] being false is the signal the UI uses to keep
/// these options off the web build's actionable surface.
const bool isSupported = false;

Future<void> sendToWifi({
  required String host,
  required int port,
  required List<int> bytes,
}) async {
  throw const PrintOutputException(
    'Wi-Fi printing is not available in the browser.',
  );
}

Future<void> sendToBluetooth({
  required String address,
  required List<int> bytes,
}) async {
  throw const PrintOutputException(
    'Bluetooth printing is not available in the browser.',
  );
}

Future<List<BluetoothPrinterCandidate>> listPaired() async {
  throw const PrintOutputException(
    'Bluetooth printing is not available in the browser.',
  );
}
