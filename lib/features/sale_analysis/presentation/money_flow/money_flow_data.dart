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
