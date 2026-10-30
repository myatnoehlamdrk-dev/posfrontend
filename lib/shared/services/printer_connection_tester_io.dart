import 'dart:async';
import 'dart:io';

import 'package:posfrontend/shared/services/printer_connection_result.dart';

/// Sockets exist everywhere except the web build.
const bool isSupported = true;

/// Opens a TCP connection to `host:port` and reports whether it completed.
///
/// A raw connect is the right probe for an ESC/POS printer: the printer's
/// listening port *is* the readiness signal, so no printer-specific command
/// needs to be sent and nothing can be accidentally printed by testing.
Future<ConnectionTestResult> testConnection(String host, int port) async {
  try {
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 3),
    );
    // Nothing is written — destroying closes the connection without leaving
    // the printer waiting on data from a client that has already given up.
    socket.destroy();
    return const ConnectionTestResult(ok: true);
  } on TimeoutException {
    return const ConnectionTestResult(
      ok: false,
      detail: 'No answer after 3 seconds.',
    );
  } on SocketException catch (e) {
    return ConnectionTestResult(ok: false, detail: e.message.trim());
  } catch (e) {
    return ConnectionTestResult(ok: false, detail: e.toString());
  }
}
