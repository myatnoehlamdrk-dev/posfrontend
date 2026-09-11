extension MapJsonExtensions on Map<String, dynamic> {
  String str(String key, [String fallback = '']) {
    final v = this[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  int integer(String key, [int fallback = 0]) {
    final v = this[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  double decimal(String key, [double fallback = 0]) {
    final v = this[key];
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  bool boolean(String key, [bool fallback = false]) {
    final v = this[key];
    if (v is bool) return v;
    return fallback;
  }
}
