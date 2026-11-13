import 'package:intl/intl.dart';

/// One month of cash movement behind the Money Flow dashboard.
///
/// [operationFee] is the operation-fee cost computed from the shop's rules for
/// the month. It is a cash outflow of its own (purchases are tracked
/// separately), so `net = inflow - outflow - operationFee`.
class MoneyFlowMonth {
  const MoneyFlowMonth({
    required this.month,
    required this.inflow,
    required this.outflow,
    required this.operationFee,
  });

  /// First day of the month.
  final DateTime month;
  final double inflow;
  final double outflow;
  final double operationFee;

  double get net => inflow - outflow - operationFee;
}

const List<String> moneyFlowMonthAbbr = [
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

/// Illustrative MMK series. November 2026 is the anchor month the dashboard
/// opens on; December 2025 exists so January has a previous month to compare
/// against.
final List<MoneyFlowMonth> moneyFlowMonths = [
  MoneyFlowMonth(
    month: DateTime(2025, 12),
    inflow: 5900000,
    outflow: 4150000,
    operationFee: 1120000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 1),
    inflow: 6200000,
    outflow: 4300000,
    operationFee: 1180000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 2),
    inflow: 6800000,
    outflow: 4600000,
    operationFee: 1290000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 3),
    inflow: 7100000,
    outflow: 4900000,
    operationFee: 1350000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 4),
    inflow: 6600000,
    outflow: 4500000,
    operationFee: 1250000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 5),
    inflow: 7400000,
    outflow: 5000000,
    operationFee: 1400000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 6),
    inflow: 7800000,
    outflow: 5200000,
    operationFee: 1480000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 7),
    inflow: 7200000,
    outflow: 4800000,
    operationFee: 1370000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 8),
    inflow: 7600000,
    outflow: 5100000,
    operationFee: 1440000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 9),
    inflow: 7900000,
    outflow: 5300000,
    operationFee: 1500000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 10),
    inflow: 8200000,
    outflow: 5400000,
    operationFee: 1560000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 11),
    inflow: 8000000,
    outflow: 5500000,
    operationFee: 1520000,
  ),
  MoneyFlowMonth(
    month: DateTime(2026, 12),
    inflow: 8400000,
    outflow: 5600000,
    operationFee: 1600000,
  ),
];

String _key(DateTime d) => '${d.year}-${d.month}';

final Map<String, MoneyFlowMonth> _byMonth = {
  for (final m in moneyFlowMonths) _key(m.month): m,
};

MoneyFlowMonth? moneyFlowMonthFor(DateTime date) =>
    _byMonth[_key(DateTime(date.year, date.month))];

/// Twelve entries for [year]; months without demo data read as zero rather
/// than disappearing from the chart.
List<MoneyFlowMonth> moneyFlowYear(int year) => [
      for (var month = 1; month <= 12; month++)
        moneyFlowMonthFor(DateTime(year, month)) ??
            MoneyFlowMonth(
              month: DateTime(year, month),
              inflow: 0,
              outflow: 0,
              operationFee: 0,
            ),
    ];

/// The month before [month], which may fall in the previous year.
DateTime previousMonthOf(DateTime month) =>
    DateTime(month.year, month.month - 1);

String moneyFlowMonthLabel(DateTime month) =>
    DateFormat('MMMM yyyy').format(month);

/// Left-axis scale for the trend chart: `8.0M`, `500K`, `0`.
String moneyFlowAxis(double value) {
  final abs = value.abs();
  if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.round().toString();
}

/// Compact figure for card footers: `8M`, `1.5M`, `340K`.
String moneyFlowCompact(double value) {
  final abs = value.abs();
  if (abs >= 1000000) return '${_trim(value / 1000000)}M';
  if (abs >= 1000) return '${_trim(value / 1000)}K';
  return value.round().toString();
}

String _trim(double value) {
  final text = value.toStringAsFixed(value.abs() >= 100 ? 0 : 1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
