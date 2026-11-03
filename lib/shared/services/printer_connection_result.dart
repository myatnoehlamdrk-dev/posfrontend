/// Outcome of a printer reachability probe.
///
/// Lives in its own file because both platform implementations return it and
/// neither may import the conditional facade (that would be circular).
class ConnectionTestResult {
  const ConnectionTestResult({required this.ok, this.detail = ''});

  /// True when something accepted a TCP connection on the printer's port.
  final bool ok;

  /// Technical reason for a failure — the raw socket message, plus the
  /// device's own network context when the platform can supply it (see the
  /// io implementation's `_explain`). Display code appends this as-is; it is
  /// diagnostics for the operator, not a translated summary.
  final String detail;
}
