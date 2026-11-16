import 'package:posfrontend/shared/services/printer_connection_result.dart';

/// No sockets on the web build; the form hides the test button instead of
/// linking `dart:io`.
const bool isSupported = false;

Future<ConnectionTestResult> testConnection(String host, int port) async {
  return const ConnectionTestResult(
    ok: false,
    detail: 'Network tests are not available in the web build.',
  );
}
