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
///
/// Failures are explained by [_explain] with what this device's own
/// interfaces say, because the mistake that produces this exact failure —
/// testing a printer with an address from another network — looks
/// indistinguishable from a printer that is simply off.
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
    return ConnectionTestResult(
      ok: false,
      detail: await _explain(host, 'No answer after 3 seconds.'),
    );
  } on SocketException catch (e) {
    return ConnectionTestResult(
      ok: false,
      detail: await _explain(host, e.message.trim()),
    );
  } catch (e) {
    return ConnectionTestResult(
      ok: false,
      detail: await _explain(host, e.toString()),
    );
  }
}

/// The raw socket failure plus this phone's own IPv4 address(es), so the
/// form can show *why* the two ends might not meet.
///
/// The scenario this exists for: a printer configured through its
/// config-mode access point (e.g. `10.10.100.254`) is later tested with an
/// address it held on an earlier network, after it switched to STA and
/// pulled a fresh DHCP lease somewhere else. To the operator both cases read
/// "could not reach the printer"; the local interface list is the only
/// signal that separates them, and it costs no packets.
Future<String> _explain(String host, String reason) async {
  final local = await _localIpv4();
  if (local.isEmpty) return reason;
  // A phone wears several interfaces at once (WiFi plus the carrier link),
  // so the matching one — the printer's own network — is what gets shown.
  final onPrintersNetwork = local.where((ip) => _sharesSubnet(host, ip));
  if (onPrintersNetwork.isNotEmpty) {
    return '$reason This phone is on ${onPrintersNetwork.join(', ')}.';
  }
  return '$reason This phone is on ${local.join(', ')} — '
      '$host looks like a different network.';
}

/// This device's IPv4 addresses, minus loopback and link-local noise.
/// Best-effort: a platform that refuses to enumerate interfaces must still
/// return the socket's own failure reason, so any error degrades to "no
/// extra context" rather than to a second failure.
Future<List<String>> _localIpv4() async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
    final addresses = <String>[
      for (final interface in interfaces)
        for (final address in interface.addresses)
          if (!address.isLoopback) address.address,
    ];
    return addresses.toSet().toList();
  } catch (_) {
    return const [];
  }
}

/// Whether two IPv4 addresses sit in the same /24 — the subnet every
/// consumer hotspot and home/office router hands out.
///
/// Deliberately coarse: `dart:io` does not expose interface netmasks, so a
/// larger subnet can be judged "different" when it is not. That only
/// withholds the warning — the phone's own address is shown either way —
/// and never hides a real mismatch, which is the case worth catching.
bool _sharesSubnet(String a, String b) {
  String prefix(String ip) {
    final parts = ip.split('.');
    return parts.length == 4 ? parts.take(3).join('.') : '';
  }

  final prefixA = prefix(a);
  return prefixA.isNotEmpty && prefixA == prefix(b);
}
