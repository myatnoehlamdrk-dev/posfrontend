// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:posfrontend/shared/services/print_output_exception.dart';
import 'package:posfrontend/shared/services/usb_printer_candidate.dart';

/// WebUSB bindings for `navigator.usb` — enough of the spec to open a
/// thermal printer on a USB cable and push ESC/POS bytes to its bulk OUT
/// endpoint. Wi-Fi and classic Bluetooth remain impossible in the browser;
/// this is the one direct thermal path a web till has.
@JS('navigator.usb')
external USBNavigator? get _usbNavigator;

@JS()
extension type USBNavigator._(JSObject _) implements JSObject {
  external JSPromise<JSArray<USBDevice>> getDevices();
  external JSPromise<USBDevice> requestDevice(JSObject options);
}

@JS()
extension type USBDevice._(JSObject _) implements JSObject {
  external int get vendorId;
  external int get productId;
  external String? get productName;
  external String? get manufacturerName;
  external String? get serialNumber;
  external bool get opened;
  external USBConfiguration? get configuration;
  external JSArray<USBConfiguration> get configurations;

  external JSPromise<JSAny?> open();
  external JSPromise<JSAny?> selectConfiguration(int configurationValue);
  external JSPromise<JSAny?> claimInterface(int interfaceNumber);
  external JSPromise<USBOutTransferResult> transferOut(
    int endpointNumber,
    JSAny data,
  );
}

@JS()
extension type USBConfiguration._(JSObject _) implements JSObject {
  external int get configurationValue;
  external JSArray<USBInterface> get interfaces;
}

@JS()
extension type USBInterface._(JSObject _) implements JSObject {
  external int get interfaceNumber;
  external JSArray<USBAlternateInterface> get alternates;
}

@JS()
extension type USBAlternateInterface._(JSObject _) implements JSObject {
  external JSArray<USBEndpoint> get endpoints;
}

@JS()
extension type USBEndpoint._(JSObject _) implements JSObject {
  external int get endpointNumber;
  external String get direction;
  external String get type;
}

@JS()
extension type USBOutTransferResult._(JSObject _) implements JSObject {
  external int get bytesWritten;
  external String get status;
}

/// Whether this browser exposes WebUSB — checked at runtime, because the
/// API needs Chromium *and* a secure context (https or localhost); Firefox
/// and plain http hosts report false even on a "web" build.
bool get isSupported => _usbNavigator != null;

// The device last granted by the chooser, remembered across sales so the
// next receipt does not need another permission prompt. WebUSB itself also
// keeps origin-level permission; these keys only let us re-find *which* of
// the permitted devices is the printer.
const _keyName = 'print_usb_name';
const _keyVendorId = 'print_usb_vendor_id';
const _keyProductId = 'print_usb_product_id';
const _keySerial = 'print_usb_serial';

/// How long the whole device stage may take before the watchdog declares
/// the printer unresponsive — long enough for a slow claim on a busy bus,
/// short enough that the operator is not left staring at silence.
const _stageTimeout = Duration(seconds: 15);

USBNavigator get _usb {
  final nav = _usbNavigator;
  if (nav == null) {
    throw const PrintOutputException(
      'USB printing is not available in this browser.',
    );
  }
  return nav;
}

/// `{ filters: [] }` — an empty filter list so the chooser shows every
/// device. Built through JSON rather than a property setter: dart:js_interop
/// has no `setProperty`, and the options bag is a plain JS object.
@JS('JSON.parse')
external JSObject _jsonParse(String source);

JSObject _requestOptions() => _jsonParse('{"filters":[]}');

/// Opens the browser's device chooser. Must run inside a user gesture (a
/// button tap) — Chrome rejects the call otherwise.
Future<UsbPrinterCandidate> requestDevice() async {
  // Empty filters = every device; the operator picks the printer by name in
  // the chooser. Filtering by class would miss the many clones that report
  // vendor-specific class instead of printer class.
  final options = _requestOptions();

  final USBDevice device;
  try {
    device = await _usb.requestDevice(options).toDart;
  } catch (e) {
    // The user dismissing the chooser arrives here as a DOMException.
    throw PrintOutputException(_friendlyChooserError(e));
  }

  final candidate = _candidateOf(device);
  await saveSelected(candidate);
  return candidate;
}

/// The remembered printer, re-resolved against [navigator.usb.getDevices]
/// (the set of devices this origin was previously granted). Null when the
/// operator has never chosen one, or the browser forgot the grant.
Future<UsbPrinterCandidate?> loadSelected() async {
  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString(_keyName);
  final vendorId = prefs.getInt(_keyVendorId);
  final productId = prefs.getInt(_keyProductId);
  if (name == null || vendorId == null || productId == null) return null;

  final remembered = UsbPrinterCandidate(
    name: name,
    vendorId: vendorId,
    productId: productId,
    serial: prefs.getString(_keySerial) ?? '',
  );

  try {
    final devices = (await _usb.getDevices().toDart).toDart;
    for (final device in devices) {
      if (device.vendorId == remembered.vendorId &&
          device.productId == remembered.productId) {
        if (remembered.serial.isEmpty ||
            (device.serialNumber ?? '') == remembered.serial) {
          return _candidateOf(device);
        }
      }
    }
  } on PrintOutputException {
    rethrow;
  } catch (_) {
    // getDevices can reject if the permission model is mid-revoke; treat
    // that as "not remembered" so the UI falls back to the chooser.
  }
  return null;
}

Future<void> saveSelected(UsbPrinterCandidate device) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyName, device.name);
  await prefs.setInt(_keyVendorId, device.vendorId);
  await prefs.setInt(_keyProductId, device.productId);
  await prefs.setString(_keySerial, device.serial);
}

Future<void> clearSelected() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyName);
  await prefs.remove(_keyVendorId);
  await prefs.remove(_keyProductId);
  await prefs.remove(_keySerial);
}

/// Opens (if needed), claims the bulk-OUT interface, and streams [bytes].
/// The device stays open between sales so the next receipt is instant —
/// the same trade the Bluetooth path makes with its kept-alive link.
Future<void> send({required List<int> bytes}) async {
  final selected = await loadSelected();
  if (selected == null) {
    throw const PrintOutputException(
      'No USB printer selected. Choose one in Print Settings.',
    );
  }

  final device = await _resolveDevice(selected);
  if (device == null) {
    throw const PrintOutputException(
      'The saved USB printer is not available. Choose it again in Print Settings.',
    );
  }

  // A trace of every step: "no error, no paper" is only decidable from how
  // far the chain got — a trace that stops mid-way means a promise that
  // never settled, a complete trace with silence means the printer took the
  // bytes and printed nothing (paper, cover, or protocol).
  debugPrint(
    '[usb] sending ${bytes.length} bytes to ${selected.name} '
    '(vid:${selected.vendorId.toRadixString(16).padLeft(4, '0')} '
    'pid:${selected.productId.toRadixString(16).padLeft(4, '0')})',
  );

  try {
    await _openClaimAndSend(device, bytes).timeout(_stageTimeout);
  } on PrintOutputException {
    rethrow;
  } on TimeoutException {
    // A promise that never settles used to leave the operator with no error
    // and no paper; the watchdog turns that silence into a sentence.
    debugPrint('[usb] device stage timed out after $_stageTimeout');
    throw const PrintOutputException(
      'The USB printer did not respond. Check its power and cable, '
      'then try again.',
    );
  } catch (e) {
    debugPrint('[usb] failed at device stage: $e');
    throw PrintOutputException(_friendlyDeviceError(e));
  }
}

/// The device stage — open, configure, claim, stream — split out so the
/// whole chain carries one watchdog timeout instead of hanging forever when
/// a browser promise never settles.
Future<void> _openClaimAndSend(USBDevice device, List<int> bytes) async {
  if (!device.opened) {
    await device.open().toDart;
  }
  await _ensureConfiguration(device);
  final endpoint = await _claimBulkOut(device);
  debugPrint('[usb] open+claim ok, bulk OUT endpoint $endpoint');
  await _transfer(device, endpoint, bytes);
  debugPrint('[usb] transfer finished cleanly');
}

Future<USBDevice?> _resolveDevice(UsbPrinterCandidate selected) async {
  final devices = (await _usb.getDevices().toDart).toDart;
  for (final device in devices) {
    if (device.vendorId == selected.vendorId &&
        device.productId == selected.productId) {
      if (selected.serial.isEmpty ||
          (device.serialNumber ?? '') == selected.serial) {
        return device;
      }
    }
  }
  return null;
}

Future<void> _ensureConfiguration(USBDevice device) async {
  if (device.configuration != null) return;
  // The device's own first configuration, not a hardcoded 1: virtually every
  // printer uses 1, but the value is a fact of the descriptor and picking it
  // wrong fails with a NotFoundError that reads to the operator like a dead
  // printer rather than a wrong guess.
  final configurations = device.configurations.toDart;
  final value = configurations.isEmpty
      ? 1
      : configurations.first.configurationValue;
  debugPrint('[usb] selecting configuration $value');
  await device.selectConfiguration(value).toDart;
}

/// Claims the first interface that exposes a bulk OUT endpoint and returns
/// that endpoint's number. Printers put it on interface 0 or on a vendor
/// interface behind a CDC pair — scanning beats assuming 0.
///
/// A refused claim is remembered, not swallowed: per the WebUSB spec it is
/// either a SecurityError (the picked interface is a *protected class* —
/// HID, mass storage, hub — which the browser never lets a page claim) or a
/// NetworkError (the OS refused exclusive control, which on Windows means
/// the printer's own driver still holds the interface). Both used to fall
/// through to "does not expose a print endpoint", so the operator was told
/// the device was wrong when the real cause was the driver or the pick.
Future<int> _claimBulkOut(USBDevice device) async {
  final configuration = device.configuration;
  if (configuration == null) {
    throw const PrintOutputException(
      'Could not open the USB printer. Unplug it and try again.',
    );
  }

  var sawPrintEndpoint = false;
  Object? firstClaimFailure;
  for (final iface in configuration.interfaces.toDart) {
    for (final alternate in iface.alternates.toDart) {
      for (final endpoint in alternate.endpoints.toDart) {
        if (endpoint.direction == 'out' && endpoint.type == 'bulk') {
          sawPrintEndpoint = true;
          try {
            await device.claimInterface(iface.interfaceNumber).toDart;
            debugPrint(
              '[usb] claimed interface ${iface.interfaceNumber} '
              '(bulk OUT endpoint ${endpoint.endpointNumber})',
            );
            return endpoint.endpointNumber;
          } catch (e) {
            // Another interface may still be claimable — keep scanning, but
            // keep the first refusal for the message below.
            firstClaimFailure ??= e;
            continue;
          }
        }
      }
    }
  }

  if (!sawPrintEndpoint) {
    throw const PrintOutputException(
      'This USB device does not expose a print endpoint.',
    );
  }
  throw PrintOutputException(_friendlyClaimError(firstClaimFailure));
}

/// WebUSB caps a single transfer (16 KB is the safe common denominator);
/// receipts are a few KB but chunking keeps large item lists from a single
/// oversized request the browser can reject.
Future<void> _transfer(
  USBDevice device,
  int endpoint,
  List<int> bytes,
) async {
  const chunkSize = 16 * 1024;
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

  for (var offset = 0; offset < data.length; offset += chunkSize) {
    final end =
        offset + chunkSize > data.length ? data.length : offset + chunkSize;
    // A chunk can come back partially written with status still "ok"; taking
    // that at face value would drop the rest of the receipt in silence, so
    // keep writing until the chunk is whole and treat a zero-progress write
    // as a dead connection instead of an infinite loop.
    var start = offset;
    while (start < end) {
      final result = await device
          .transferOut(endpoint, data.sublist(start, end).toJS)
          .toDart;
      debugPrint(
        '[usb] transferOut ${end - start} bytes -> status=${result.status} '
        'written=${result.bytesWritten}',
      );
      if (result.status != 'ok') {
        throw PrintOutputException(
          result.status == 'babble'
              ? 'The USB printer reported an overflow. Check the cable and try again.'
              : 'The USB printer did not accept the receipt. Check the connection.',
        );
      }
      if (result.bytesWritten <= 0) {
        throw const PrintOutputException(
          'The USB printer stopped accepting data. Check the connection.',
        );
      }
      start += result.bytesWritten;
    }
  }
}

UsbPrinterCandidate _candidateOf(USBDevice device) {
  final product = device.productName?.trim();
  final manufacturer = device.manufacturerName?.trim();
  final name = (product == null || product.isEmpty)
      ? (manufacturer == null || manufacturer.isEmpty)
          ? 'USB printer'
          : manufacturer
      : (manufacturer == null ||
              manufacturer.isEmpty ||
              product.contains(manufacturer))
          ? product
          : '$manufacturer $product';

  return UsbPrinterCandidate(
    name: name,
    vendorId: device.vendorId,
    productId: device.productId,
    serial: device.serialNumber ?? '',
  );
}

String _friendlyChooserError(Object error) {
  final text = error.toString();
  if (text.contains('No device selected')) {
    return 'No printer was chosen.';
  }
  if (text.contains('SecurityError') || text.contains('allowed')) {
    // Per the WebUSB spec requestDevice only rejects with SecurityError when
    // it lost its transient user activation ("Must be handling a user
    // gesture") — the picker itself is fine, the tap got lost. The raw
    // browser text rides along so the next failure says which it was.
    return 'USB permission was denied. Tap Choose again directly '
        '(the page must run on HTTPS or localhost). ($text)';
  }
  return 'Could not open the USB printer chooser. ($text)';
}

String _friendlyDeviceError(Object error) {
  final text = error.toString();
  if (text.contains('No device selected') || text.contains('NotFoundError')) {
    return 'The USB printer was unplugged. Plug it in and choose it again.';
  }
  if (text.contains('InvalidStateError') || text.contains('busy')) {
    return 'The USB printer is busy. Close other tabs using it and try again.';
  }
  if (text.contains('SecurityError')) {
    return 'USB permission was denied. Choose the printer again in '
        'Print Settings. ($text)';
  }
  // open() and selectConfiguration() reject with NetworkError when the
  // platform refuses the session — on Windows that is the printer's own
  // driver (usbprint.sys or the vendor's) still holding the interface, so
  // the browser, which can only talk WinUSB, is turned away. The cable and
  // the chooser are fine; blaming the connection here is what made a
  // plugged-in printer look broken.
  if (text.contains('Access denied') || text.contains('NetworkError')) {
    return 'The system driver is using this printer, so the browser cannot '
        'control it. Close any program printing to it and try again '
        '(on Windows the printer must be bound to WinUSB). ($text)';
  }
  return 'Could not send to the USB printer. Check the connection. ($text)';
}

String _friendlyClaimError(Object? error) {
  final text = error?.toString() ?? '';
  if (text.contains('SecurityError')) {
    return 'The browser refuses to claim protected devices (HID, storage, '
        'hub) — pick the printer itself in the chooser, not another USB '
        'device. ($text)';
  }
  return _friendlyDeviceError(error ?? '');
}
