String _abbreviated(double value) {
  final text = value.abs() >= 100
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

extension NumberFormatting on num {
  String withCommas() {
    final digits = toInt().abs().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return this < 0 ? '-$withCommas' : withCommas;
  }

  /// Shortens large figures so a KPI stays narrow: `300000` -> `300K`,
  /// `1250000` -> `1.3M`. Values under a thousand are shown unchanged.
  String compact() {
    if (abs() < 1000) return round().toString();
    if (abs() < 1000000) return '${_abbreviated(this / 1000)}K';
    if (abs() < 1000000000) return '${_abbreviated(this / 1000000)}M';
    return '${_abbreviated(this / 1000000000)}B';
  }

  String asCurrency([String symbol = 'MMK']) => '$symbol ${withCommas()}';

  /// Renders `10` rather than `10.0`, so a whole percentage reads cleanly on
  /// screen and on paper. Genuine fractions keep [decimals] places.
  ///
  /// The totals panel, the PDF receipt and the saved value all format the same
  /// discount, and they have to agree: raw interpolation would print `10.0%` on
  /// a receipt for a discount the screen calls `10%` and the database stores as
  /// `10`.
  String asPercent([int decimals = 2]) =>
      this == roundToDouble() ? toStringAsFixed(0) : toStringAsFixed(decimals);
}
