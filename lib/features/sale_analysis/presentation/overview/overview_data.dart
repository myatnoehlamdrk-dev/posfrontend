/// One month of sale-performance figures for the Overview tab.
///
/// Every field is a real figure: revenue, COGS and the operation fee come
/// from the API, and the derived values below are pure arithmetic on them.
/// There is deliberately no demo series in this file — an empty month reads
/// as zero, and the screen shows an empty state rather than invented numbers.
class OverviewMonth {
  const OverviewMonth({
    required this.month,
    required this.revenue,
    required this.cogsValue,
    required this.operationFee,
    required this.unitsSold,
    required this.transactions,
  });

  /// First day of the month.
  final DateTime month;
  final double revenue;

  /// Cost of goods for the month, from variant cost price × quantity.
  final double cogsValue;
  final double operationFee;
  final int unitsSold;
  final int transactions;

  double get cogs => cogsValue;
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
