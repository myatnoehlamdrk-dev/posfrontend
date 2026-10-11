/// Whether the app may accept writes it cannot deliver immediately.
///
/// ## Why this is off by default
///
/// Queueing a sale and replaying it later is only safe if the server can
/// tell two identical POSTs apart. The backend does not have that yet (no
/// unique `Idempotency-Key` handling, no client UUID column), so a flush
/// after an ambiguous failure — request sent, response lost — could record
/// the same sale twice. For a POS, a duplicate sale is worse than a refused
/// one: it corrupts stock and the day's takings.
///
/// So the outbox ships **built, tested, and disabled**: reads (the offline
/// catalog) work for everyone, writes queue only when the app is built with
///
/// ```
/// flutter build apk --dart-define=OFFLINE_WRITES=true
/// ```
///
/// at which point the trade above is accepted deliberately — and the
/// `Idempotency-Key` header is already being sent, so enabling it against a
/// backend that implements the server half is a config change, not a code
/// change.
///
/// Mutable (rather than a compile-time `const`) so tests can exercise both
/// paths; production code never assigns it.
class OfflineWrites {
  OfflineWrites._();

  static bool enabled = bool.fromEnvironment('OFFLINE_WRITES');

  /// Test seam.
  static void reset() => enabled = bool.fromEnvironment('OFFLINE_WRITES');
}
