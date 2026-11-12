/// One month of sale-performance figures for the Overview tab.
///
/// Revenue and the operation fee line up with the Money Flow tab's 2026 series,
/// and COGS is fixed at 60.2% of revenue so the gross margin (39.8%) matches the
/// "before fees" margin quoted by the Operation Fee Controller.
class OverviewMonth {
  const OverviewMonth({
    required this.month,
    required this.revenue,
    required this.operationFee,
    required this.unitsSold,
    required this.transactions,
  });

  /// First day of the month.
  final DateTime month;
  final double revenue;
  final double operationFee;
  final int unitsSold;
  final int transactions;

  double get cogs => revenue * 0.602;
  double get grossProfit => revenue - cogs;
  double get marginPct => revenue == 0 ? 0 : grossProfit / revenue * 100;
  double get aov => transactions == 0 ? 0 : revenue / transactions;
  double get avgUnits => transactions == 0 ? 0 : unitsSold / transactions;
  double get netProfit => grossProfit - operationFee;
}

const List<String> overviewMonthAbbr = [
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

final List<OverviewMonth> overviewMonths = [
  OverviewMonth(
    month: DateTime(2026, 1),
    revenue: 6200000,
    operationFee: 1180000,
    unitsSold: 2450,
    transactions: 980,
  ),
  OverviewMonth(
    month: DateTime(2026, 2),
    revenue: 6800000,
    operationFee: 1290000,
    unitsSold: 2688,
    transactions: 1075,
  ),
  OverviewMonth(
    month: DateTime(2026, 3),
    revenue: 7100000,
    operationFee: 1350000,
    unitsSold: 2808,
    transactions: 1123,
  ),
  OverviewMonth(
    month: DateTime(2026, 4),
    revenue: 6600000,
    operationFee: 1250000,
    unitsSold: 2610,
    transactions: 1044,
  ),
  OverviewMonth(
    month: DateTime(2026, 5),
    revenue: 7400000,
    operationFee: 1400000,
    unitsSold: 2928,
    transactions: 1171,
  ),
  OverviewMonth(
    month: DateTime(2026, 6),
    revenue: 7800000,
    operationFee: 1480000,
    unitsSold: 3085,
    transactions: 1234,
  ),
  OverviewMonth(
    month: DateTime(2026, 7),
    revenue: 7200000,
    operationFee: 1370000,
    unitsSold: 2848,
    transactions: 1139,
  ),
  OverviewMonth(
    month: DateTime(2026, 8),
    revenue: 7600000,
    operationFee: 1440000,
    unitsSold: 3008,
    transactions: 1203,
  ),
  OverviewMonth(
    month: DateTime(2026, 9),
    revenue: 7900000,
    operationFee: 1500000,
    unitsSold: 3125,
    transactions: 1250,
  ),
  OverviewMonth(
    month: DateTime(2026, 10),
    revenue: 8200000,
    operationFee: 1560000,
    unitsSold: 3243,
    transactions: 1297,
  ),
  OverviewMonth(
    month: DateTime(2026, 11),
    revenue: 8000000,
    operationFee: 1520000,
    unitsSold: 3160,
    transactions: 1264,
  ),
  OverviewMonth(
    month: DateTime(2026, 12),
    revenue: 8400000,
    operationFee: 1600000,
    unitsSold: 3323,
    transactions: 1329,
  ),
];

String _key(DateTime d) => '${d.year}-${d.month}';

final Map<String, OverviewMonth> _byMonth = {
  for (final m in overviewMonths) _key(m.month): m,
};

OverviewMonth? overviewMonthFor(DateTime date) =>
    _byMonth[_key(DateTime(date.year, date.month))];
