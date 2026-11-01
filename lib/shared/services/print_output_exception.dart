/// A print failure written for the operator standing at the till.
///
/// Unlike the API exceptions, this message is already user-facing and needs
/// no mapping, so [toString] returns it verbatim — the snackbar formats
/// `Thermal printing failed: {v1}` around whatever this string says.
class PrintOutputException implements Exception {
  const PrintOutputException(this.message);

  final String message;

  @override
  String toString() => message;
}
