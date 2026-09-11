extension NumberFormatting on num {
  String withCommas() {
    final digits = toInt().abs().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return this < 0 ? '-$withCommas' : withCommas;
  }

  String asCurrency([String symbol = 'MMK']) => '$symbol ${withCommas()}';
}
