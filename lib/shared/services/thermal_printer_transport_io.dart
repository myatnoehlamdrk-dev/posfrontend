import 'dart:async';
import 'dart:io';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'package:posfrontend/shared/services/bluetooth_printer_candidate.dart';
import 'package:posfrontend/shared/services/print_output_exception.dart';

const bool isSupported = true;

/// The address the adapter is currently connected to, so a second sale to the
/// same printer reuses the link while a *different* printer triggers a
/// disconnect first — otherwise bytes would silently go to the old device.
String? _activeAddress;

Future<void> sendToWifi({
  required String host,
  required int port,
  required List<int> bytes,
}) async {
  Socket? socket;
  try {
    socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 3),
    );
    socket.add(bytes);
    await socket.flush().timeout(const Duration(seconds: 3));
    // Graceful FIN, not destroy(): a printer mid-receipt must not be handed
    // a reset. Printers that never close their side still complete — the
    // flush above already put the job on the wire.
    await socket.close().timeout(const Duration(seconds: 3));
  } on SocketException {
    throw PrintOutputException('Could not reach the printer at $host:$port.');
  } on TimeoutException {
    throw PrintOutputException('The printer at $host:$port did not respond.');
  } finally {
    socket?.destroy();
  }
}

Future<void> sendToBluetooth({
  required String address,
  required List<int> bytes,
}) async {
  await _ensurePermission();

  if (!await PrintBluetoothThermal.bluetoothEnabled) {
    throw const PrintOutputException(
      'Bluetooth is turned off. Turn it on and try again.',
    );
  }

  if (await PrintBluetoothThermal.connectionStatus &&
      _activeAddress != address) {
    await PrintBluetoothThermal.disconnect;
    _activeAddress = null;
  }
  if (!await PrintBluetoothThermal.connectionStatus) {
    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: address,
    );
    if (!connected) {
      // No address in the message: it is a machine id, and the picker
      // already showed the operator which printer this is.
      throw const PrintOutputException('Could not connect to the printer.');
    }
    _activeAddress = address;
  }

  final written = await PrintBluetoothThermal.writeBytes(bytes);
  if (!written) {
    // The link went stale under us — drop it so the next sale reconnects
    // instead of failing twice.
    _activeAddress = null;
    throw const PrintOutputException(
      'The printer did not receive the receipt. Move it closer and try again.',
    );
  }
}

Future<List<BluetoothPrinterCandidate>> listPaired() async {
  await _ensurePermission();

  if (!await PrintBluetoothThermal.bluetoothEnabled) {
    throw const PrintOutputException(
      'Bluetooth is turned off. Turn it on and try again.',
    );
  }

  final items = await PrintBluetoothThermal.pairedBluetooths;
  return [
    for (final item in items)
      BluetoothPrinterCandidate(name: item.name, address: item.macAdress),
  ];
}

/// Asks for (and waits out) the platform's Bluetooth consent.
///
/// Android 12+ blocks inside the plugin until the operator answers the
/// system dialog, so the first check is already accurate. iOS answers
/// immediately with "not determined" while its prompt is still on screen —
/// hence the poll, which turns the time the operator spends reading the
/// dialog into the wait.
Future<void> _ensurePermission() async {
  if (await PrintBluetoothThermal.isPermissionBluetoothGranted) return;
  if (Platform.isIOS) {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (await PrintBluetoothThermal.isPermissionBluetoothGranted) return;
    }
  }
  throw const PrintOutputException('Bluetooth permission was denied.');
}
