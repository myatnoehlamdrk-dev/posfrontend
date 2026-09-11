extension StringExtensions on String? {
  String orDash() {
    if (this == null) return '—';
    final trimmed = this!.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }

  String orEmpty() => this?.trim() ?? '';
}
