import 'package:posfrontend/shared/services/printer_connection_result.dart';
import 'package:posfrontend/shared/services/printer_connection_tester_io.dart'
    if (dart.library.js_interop) 'package:posfrontend/shared/services/printer_connection_tester_web.dart'
    as impl;

/// Probes whether a printer at `host:port` is reachable on the network.
///
/// The platform split behind the import is what keeps the web build alive:
/// `dart:io` sockets do not exist there, so the web build links a stub that
/// reports [isSupported] false rather than failing the compile. Callers hide
/// their test affordance on unsupported platforms instead of showing a button
/// that can only ever fail.
abstract final class PrinterConnectionTester {
  /// Whether this platform can open raw sockets at all.
  static bool get isSupported => impl.isSupported;

  static Future<ConnectionTestResult> test(String host, int port) =>
      impl.testConnection(host, port);
}
