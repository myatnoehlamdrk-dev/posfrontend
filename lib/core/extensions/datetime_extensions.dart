/// Display formatting for timestamps, in the device's local time.
///
/// Every one of these converts through [DateTime.toLocal] first, and that is
/// the whole point of the file rather than a detail of it.
///
/// The API serialises timestamps with `->toISOString()` -- UTC, with a trailing
/// `Z` -- and `DateTime.parse` honours that marker by returning a **UTC**
/// DateTime. Reading `.hour`/`.day` off such a value prints UTC wall-clock
/// time, which for Myanmar (UTC+6:30) is six and a half hours behind: a sale
/// made at 2:25pm showed as "7:54 AM". Converting here means every caller is
/// correct by construction, instead of each screen having to remember.
///
/// Times the app creates itself (`DateTime.now()`) are already local, and
/// `toLocal()` on a local DateTime is a no-op -- so this is safe for both
/// kinds of input.
extension DateTimeFormatting on DateTime {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String toFormattedDate() {
    final local = toLocal();
    return '${_months[local.month - 1]} ${local.day}, ${local.year}';
  }

  String toFormattedDateTime() {
    final local = toLocal();
    final h = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final m = local.minute.toString().padLeft(2, '0');
    return '${toFormattedDate()} $h:$m $ampm';
  }

  String toShortDate() {
    final local = toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  /// `YYYY-MM-DD HH:mm`, 24-hour, local.
  ///
  /// The shape several screens hand-rolled before this existed; kept here so
  /// they cannot drift apart again.
  String toCompactDateTime() {
    final local = toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}  '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
