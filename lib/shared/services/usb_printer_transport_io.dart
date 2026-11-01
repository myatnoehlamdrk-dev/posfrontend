import 'package:posfrontend/shared/services/usb_printer_candidate.dart';

/// Native builds have no WebUSB: Bluetooth and Wi-Fi already cover direct
/// thermal output there, so the USB option stays off rather than offering a
/// path with no implementation behind it.
final bool isSupported = false;

Future<UsbPrinterCandidate> requestDevice() async {
  throw UnsupportedError('WebUSB is only available in the browser.');
}

Future<UsbPrinterCandidate?> loadSelected() async => null;

Future<void> saveSelected(UsbPrinterCandidate device) async {}

Future<void> clearSelected() async {}

Future<void> send({required List<int> bytes}) async {
  throw UnsupportedError('WebUSB is only available in the browser.');
}
