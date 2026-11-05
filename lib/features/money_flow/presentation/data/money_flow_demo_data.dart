import 'package:flutter/material.dart';

/// Formats whole MMK with thousands separators: `250,000`.
///
/// The summary cards quote millions (`8.0M`) but an individual movement is
/// always a full amount, and `8.0M` beside `250000` gives the reader two
/// unrecognisable notations for the same currency.
String formatMmk(double amount) {
  var digits = amount.round().toString();
  final negative = digits.startsWith('-');
  if (negative) digits = digits.substring(1);
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return negative ? '-$out' : '$out';
}

/// One line of the financial ledger behind the Recent Transactions list.
class MoneyFlowTransaction {
  const MoneyFlowTransaction({
    required this.description,
    required this.category,
    required this.account,
    required this.when,
    required this.amount,
    required this.isInflow,
  });

  /// What happened, e.g. `Customer Payment`.
  final String description;

  /// Grouping, e.g. `Sales`, `Purchase`, `Expense`.
  final String category;

  /// Where the money moved, e.g. `Cash`, `Bank`, `Wallet`.
  final String account;

  final DateTime when;

  /// Whole MMK, always positive — the sign comes from [isInflow].
  final double amount;

  final bool isInflow;

  String get signed => '${isInflow ? '+' : '-'}${formatMmk(amount)}';
}

/// Inflow, outflow and the balance they leave behind for one date range.
///
/// All three are in millions, matching the summary cards.
class MoneyFlowTotals {
  const MoneyFlowTotals({required this.inflow, required this.outflow});

  final double inflow;
  final double outflow;

  double get net => inflow - outflow;

  double get closing => MoneyFlowDemoData.openingBalance + net;
}

/// Demo figures behind the Money Flow Analysis dashboard.
///
/// Everything here is illustrative MMK for MDRK POS. The summary and trend
/// series are held in millions (`8.0M` inflow for November 2026); the ledger
/// holds whole MMK (`250,000`), which is how each is quoted on screen.
class MoneyFlowDemoData {
  const MoneyFlowDemoData();

  static const List<String> monthAbbr = [
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

  // November 2026 anchors quoted by the dashboard cards: 8.0M in, 5.5M out,
  // +2.5M net, 7.5M closing.
  static const double monthInflow = 8.0; // millions
  static const double monthOutflow = 5.5; // millions
  static const double openingBalance = 5.0; // millions

  /// The demo month the `This Month` preset opens on.
  static final DateTime demoNow = DateTime(2026, 11, 30);

  static const List<String> periodPresets = [
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Custom',
  ];

  /// Granularity selector on the cash flow trend. All four are always offered
  /// so the control the spec asks for never disappears; a short range simply
  /// lands in fewer buckets.
  static const List<String> granularities = [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  /// Where the money came from, as a share of the range's inflow.
  static const List<(String, double)> inflowSources = [
    ('Sales payments', 0.62),
    ('Customer debt collection', 0.23),
    ('Other income', 0.15),
  ];

  /// Where the money went, as a share of the range's outflow.
  static const List<(String, double)> outflowSources = [
    ('Inventory payments', 0.44),
    ('Operating expenses', 0.26),
    ('Salary payments', 0.20),
    ('Customer refunds', 0.10),
  ];

  /// The ledger, newest first.
  static final List<MoneyFlowTransaction> ledger = [
    MoneyFlowTransaction(
      description: 'Customer Payment',
      category: 'Sales',
      account: 'Cash',
      when: DateTime(2026, 11, 28, 14, 30),
      amount: 250000,
      isInflow: true,
    ),
    MoneyFlowTransaction(
      description: 'Inventory Purchase',
      category: 'Purchase',
      account: 'Bank',
      when: DateTime(2026, 11, 28, 11, 5),
      amount: 500000,
      isInflow: false,
    ),
    MoneyFlowTransaction(
      description: 'Electricity Bill',
      category: 'Expense',
      account: 'Cash',
      when: DateTime(2026, 11, 27, 9, 15),
      amount: 80000,
      isInflow: false,
    ),
    MoneyFlowTransaction(
      description: 'Customer Debt Collection',
      category: 'Receivable',
      account: 'Bank',
      when: DateTime(2026, 11, 27, 16, 40),
      amount: 1200000,
      isInflow: true,
    ),
    MoneyFlowTransaction(
      description: 'Salary Payment',
      category: 'Payroll',
      account: 'Bank',
      when: DateTime(2026, 11, 26, 10, 0),
      amount: 900000,
      isInflow: false,
    ),
    MoneyFlowTransaction(
      description: 'Walk-in Sales',
      category: 'Sales',
      account: 'Cash',
      when: DateTime(2026, 11, 26, 18, 20),
      amount: 640000,
      isInflow: true,
    ),
    MoneyFlowTransaction(
      description: 'Supplier Payment',
      category: 'Purchase',
      account: 'Bank',
      when: DateTime(2026, 11, 25, 13, 10),
      amount: 750000,
      isInflow: false,
    ),
    MoneyFlowTransaction(
      description: 'Rent Payment',
      category: 'Expense',
      account: 'Bank',
      when: DateTime(2026, 11, 24, 9, 0),
      amount: 400000,
      isInflow: false,
    ),
    MoneyFlowTransaction(
      description: 'Online Order Payout',
      category: 'Sales',
      account: 'Wallet',
      when: DateTime(2026, 11, 23, 20, 5),
      amount: 320000,
      isInflow: true,
    ),
    MoneyFlowTransaction(
      description: 'Customer Refund',
      category: 'Refund',
      account: 'Cash',
      when: DateTime(2026, 11, 23, 12, 30),
      amount: 45000,
      isInflow: false,
    ),
    MoneyFlowTransaction(
      description: 'Bulk Sale',
      category: 'Sales',
      account: 'Bank',
      when: DateTime(2026, 11, 22, 15, 45),
      amount: 1500000,
      isInflow: true,
    ),
    MoneyFlowTransaction(
      description: 'Internet & Phone',
      category: 'Expense',
      account: 'Wallet',
      when: DateTime(2026, 11, 21, 8, 30),
      amount: 60000,
      isInflow: false,
    ),
  ];

  // ---------------------------------------------------------------------
  // Daily series
  // ---------------------------------------------------------------------

  static const List<double> _inShape = [
    0.22,
    0.3,
    0.26,
    0.34,
    0.4,
    0.28,
    0.36,
  ];
  static const List<double> _outShape = [
    0.3,
    0.24,
    0.32,
    0.26,
    0.36,
    0.22,
    0.3,
  ];

  /// Day-of-month ramp: 0.7x on the 1st through 1.3x on the last day, so money
  /// moves visibly grow across the month.
  double _dayRamp(DateTime d) {
    final daysInMonth = DateTime(d.year, d.month + 1, 0).day;
    if (daysInMonth <= 1) return 1;
    return 0.7 + 0.6 * (d.day - 1) / (daysInMonth - 1);
  }

  /// Share of the month that falls on [d]: shaped by [raw], weighted by the
  /// day ramp, and renormalised so the month's shares still add up to exactly
  /// 1. The anchors above therefore never move when the shape changes.
  double _monthShare(DateTime d, double Function(int day) raw) {
    final daysInMonth = DateTime(d.year, d.month + 1, 0).day;
    var total = 0.0;
    for (var day = 1; day <= daysInMonth; day++) {
      total += raw(day) * _dayRamp(DateTime(d.year, d.month, day));
    }
    if (total == 0) return 1 / daysInMonth;
    return raw(d.day) * _dayRamp(d) / total;
  }

  int _monthsBack(DateTime d) => (2026 - d.year) * 12 + (11 - d.month);

  /// How far a month sits from the November 2026 anchor. Past months divide by
  /// [rate] once a month, future ones multiply, so a wide range trends instead
  /// of repeating one month's figure.
  double _factor(int monthsBack, double rate) {
    var factor = 1.0;
    for (var i = 0; i < monthsBack.abs(); i++) {
      factor *= rate;
    }
    return monthsBack >= 0 ? 1 / factor : factor;
  }

  /// Money received on one day, in millions.
  double inflowDaily(DateTime d) =>
      monthInflow * _factor(_monthsBack(d), 1.08) *
      _monthShare(d, (day) => _inShape[(day + d.month) % _inShape.length]);

  /// Money paid out on one day, in millions.
  double outflowDaily(DateTime d) =>
      monthOutflow * _factor(_monthsBack(d), 1.06) *
      _monthShare(
        d,
        (day) => _outShape[(day + d.month * 3) % _outShape.length],
      );

  // ---------------------------------------------------------------------
  // Aggregation
  // ---------------------------------------------------------------------

  /// Inflow, outflow and closing balance for a range.
  MoneyFlowTotals totalsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var inflow = 0.0;
    var outflow = 0.0;
    var day = start;
    while (!day.isAfter(end)) {
      inflow += inflowDaily(day);
      outflow += outflowDaily(day);
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return MoneyFlowTotals(inflow: inflow, outflow: outflow);
  }

  /// Inflow and outflow per bucket for the trend chart. Every day lands in
  /// exactly one bucket, so the buckets always add back to [totalsFor].
  ({List<String> labels, List<double> inflow, List<double> outflow})
  trendBuckets(DateTimeRange range, String granularity) {
    final start = DateUtils.dateOnly(range.start);
    final end = DateUtils.dateOnly(range.end);
    final order = <String>[];
    final first = <String, DateTime>{};
    final inflow = <String, double>{};
    final outflow = <String, double>{};

    var day = start;
    while (!day.isAfter(end)) {
      final key = _bucketKey(day, granularity);
      if (!first.containsKey(key)) {
        order.add(key);
        first[key] = day;
      }
      inflow[key] = (inflow[key] ?? 0) + inflowDaily(day);
      outflow[key] = (outflow[key] ?? 0) + outflowDaily(day);
      day = DateTime(day.year, day.month, day.day + 1);
    }

    final labels = <String>[];
    final inf = <double>[];
    final out = <double>[];
    for (var i = 0; i < order.length; i++) {
      final key = order[i];
      labels.add(_labelFor(first[key]!, granularity, i, start, end));
      inf.add(inflow[key] ?? 0);
      out.add(outflow[key] ?? 0);
    }
    return (labels: labels, inflow: inf, outflow: out);
  }

  String _bucketKey(DateTime d, String granularity) => switch (granularity) {
    'Yearly' => 'y${d.year}',
    'Monthly' => 'm${d.year}-${d.month}',
    'Weekly' => 'w${_weekStart(d).millisecondsSinceEpoch}',
    _ => 'd${d.year}-${d.month}-${d.day}',
  };

  DateTime _weekStart(DateTime d) => DateTime(
    d.year,
    d.month,
    d.day + (DateTime.monday - d.weekday) % 7,
  );

  String _labelFor(
    DateTime first,
    String granularity,
    int index,
    DateTime start,
    DateTime end,
  ) => switch (granularity) {
    'Yearly' => '${first.year}',
    'Monthly' => start.year == end.year
        ? monthAbbr[first.month - 1]
        : '${monthAbbr[first.month - 1]} ${first.year.toString().substring(2)}',
    'Weekly' => 'W${index + 1}',
    _ => '${first.day}',
  };

  /// Dates a period preset opens on. Fixed rather than `DateTime.now()`, so the
  /// demo always lands on the month its anchors describe.
  static DateTimeRange rangeForPreset(String preset) => switch (preset) {
    'Last Month' => DateTimeRange(
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 31),
    ),
    'Last 3 Months' => DateTimeRange(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 11, 30),
    ),
    _ => DateTimeRange(
      start: DateTime(2026, 11, 1),
      end: DateTime(2026, 11, 30),
    ),
  };

  // ---------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------

  bool isMonthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0).day == d.day;

  /// Millions, with thousands for small figures: 8.0M, 250.0K.
  String money(double millions) {
    if (millions.abs() >= 0.1) return '${millions.toStringAsFixed(1)}M';
    return '${(millions * 1000).toStringAsFixed(1)}K';
  }

  /// Percentage change with direction. A move smaller than a rounding step is a
  /// dash rather than a misleading `↑ 0.0%`.
  String change(double current, double previous) {
    if (previous == 0) return '—';
    final pct = (current - previous) / previous * 100;
    if (pct.abs() < 0.05) return '—';
    return '${pct > 0 ? '↑' : '↓'} ${pct.abs().toStringAsFixed(1)}%';
  }

  /// "Nov 2026" for a whole month, otherwise the explicit date span.
  String rangeLabelFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    if (start.day == 1 && isMonthEnd(end)) {
      if (start.year == end.year && start.month == end.month) {
        return '${monthAbbr[start.month - 1]} ${start.year}';
      }
      if (start.year == end.year) {
        return '${monthAbbr[start.month - 1]}–'
            '${monthAbbr[end.month - 1]} ${end.year}';
      }
      return '${monthAbbr[start.month - 1]} ${start.year} – '
          '${monthAbbr[end.month - 1]} ${end.year}';
    }
    return '${_shortDate(start)} – ${_shortDate(end)}';
  }

  /// 28 Nov 2026
  String _shortDate(DateTime d) =>
      '${d.day} ${monthAbbr[d.month - 1]} ${d.year}';

  /// The period immediately before [r], so the summary cards can quote a
  /// percentage change against it.
  DateTimeRange previousPeriod(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    if (start.day == 1 && isMonthEnd(end)) {
      final months =
          (end.year - start.year) * 12 + (end.month - start.month) + 1;
      return DateTimeRange(
        start: DateTime(start.year, start.month - months, 1),
        end: DateTime(start.year, start.month, 0),
      );
    }
    final days = end.difference(start).inDays + 1;
    return DateTimeRange(
      start: DateUtils.dateOnly(start.subtract(Duration(days: days))),
      end: DateUtils.dateOnly(start.subtract(const Duration(days: 1))),
    );
  }

  /// 28 Nov 2026, 14:30
  String dateTimeLabel(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${_shortDate(d)}, $hh:$mm';
  }
}
