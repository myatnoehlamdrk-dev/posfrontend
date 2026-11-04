import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Demo figures and date maths behind the Sale Analysis detail pages.
///
/// Every figure is derived from the same deterministic daily series, so the
/// KPIs, breakdowns and comparisons all move together with the picked range.
/// Comparing a range against itself is how you get a page that says 15M at the
/// top and 13.3M in the table below.
class SaleAnalysisDemoData {
  const SaleAnalysisDemoData();

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

  /// Labels for the fixed eight-day demo series used by the secondary pages.
  static const List<String> novemberDayLabels = [
    'Nov 1',
    'Nov 2',
    'Nov 3',
    'Nov 4',
    'Nov 5',
    'Nov 6',
    'Nov 7',
    'Nov 8',
  ];

  /// Demo mix of the total. Shares, not absolute amounts, so the breakdowns
  /// always add up to whatever the selected range totals.
  static const List<String> categoryNames = [
    'Electronics',
    'Accessories',
    'Computer',
    'Others',
  ];
  static const List<double> categoryShares = [0.4467, 0.2667, 0.18, 0.1066];

  static const List<String> paymentNames = [
    'Cash',
    'Bank transfer',
    'Mobile payment',
    'Credit',
  ];
  static const List<double> paymentShares = [0.4467, 0.2667, 0.18, 0.1066];

  /// Product and its share of total revenue.
  static const List<(String, double)> topProducts = [
    ('Headphones', 0.26),
    ('Keyboard', 0.1733),
    ('Mouse', 0.1333),
  ];

  /// Voucher, ISO date, customer, payment, status, amount.
  /// Amounts average ~84K, the AOV the KPI cards quote.
  static const List<List<String>> transactions = [
    ['SAL-001', '2026-11-03', 'Customer A', 'Cash', 'Completed', '75,000'],
    ['SAL-002', '2026-11-03', 'Customer B', 'Bank', 'Completed', '62,000'],
    ['SAL-003', '2026-11-03', 'Customer C', 'Credit', 'Pending', '145,000'],
    ['SAL-004', '2026-11-01', 'Customer D', 'Cash', 'Completed', '90,000'],
    ['SAL-005', '2026-10-29', 'Customer E', 'Bank', 'Completed', '48,000'],
  ];

  /// Only the granularities the range can support.
  List<String> granularitiesFor(DateTimeRange range) => [
    'Daily',
    if (coversFullWeek(range)) 'Weekly',
    if (coversFullMonth(range)) 'Monthly',
  ];

  /// True when the range contains at least one complete Monday–Sunday week.
  bool coversFullWeek(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var monday = DateTime(
      start.year,
      start.month,
      start.day + (DateTime.monday - start.weekday) % 7,
    );
    while (!monday.isAfter(end)) {
      final sunday = DateTime(monday.year, monday.month, monday.day + 6);
      if (!sunday.isAfter(end)) return true;
      monday = DateTime(monday.year, monday.month, monday.day + 7);
    }
    return false;
  }

  /// True when the range contains at least one complete calendar month.
  bool coversFullMonth(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var month = DateTime(start.year, start.month, 1);
    while (!month.isAfter(end)) {
      final monthEnd = DateTime(month.year, month.month + 1, 0);
      if (!month.isBefore(start) && !monthEnd.isAfter(end)) return true;
      month = DateTime(month.year, month.month + 1, 1);
    }
    return false;
  }

  /// Chart points for the active granularity. Every bucket is the sum of the
  /// same demo daily series, so a week adds up to its seven days and a month
  /// to the 15M the KPI cards quote.
  ({List<String> labels, List<double> values}) trendBuckets(
    DateTimeRange range,
    String granularity,
  ) => _buckets(range, granularity, dailyValue);

  /// Same buckets as [trendBuckets], but summed from the COGS daily series.
  ({List<String> labels, List<double> values}) cogsTrendBuckets(
    DateTimeRange range,
    String granularity,
  ) => _buckets(range, granularity, cogsDailyValue);

  /// Same buckets as [trendBuckets], but summed from the gross-profit series.
  ({List<String> labels, List<double> values}) grossProfitTrendBuckets(
    DateTimeRange range,
    String granularity,
  ) => _buckets(range, granularity, grossProfitDailyValue);

  /// Margin per bucket. Margin is a percentage, so buckets average their days
  /// instead of summing them.
  ({List<String> labels, List<double> values}) marginTrendBuckets(
    DateTimeRange range,
    String granularity,
  ) => _buckets(range, granularity, marginDailyValue, average: true);

  /// Same buckets as [trendBuckets], but summed from the units-sold series.
  ({List<String> labels, List<double> values}) unitsTrendBuckets(
    DateTimeRange range,
    String granularity,
  ) => _buckets(range, granularity, unitsDailyValue);

  /// Same buckets as [trendBuckets], but summed from the transaction series.
  ({List<String> labels, List<double> values}) transactionsTrendBuckets(
    DateTimeRange range,
    String granularity,
  ) => _buckets(range, granularity, transactionsDailyValue);

  /// Same buckets as [trendBuckets], but summed from the AOV series.
  ({List<String> labels, List<double> values}) aovTrendBuckets(
    DateTimeRange range,
    String granularity,
  ) => _buckets(range, granularity, aovDailyValue);

  /// Same buckets as [trendBuckets], but summed from the avg-units series.
  ({List<String> labels, List<double> values}) avgUnitsTrendBuckets(
    DateTimeRange range,
    String granularity,
  ) => _buckets(range, granularity, avgUnitsDailyValue);

  /// Same buckets as [trendBuckets], but summed from the operating-expense
  /// series.
  ({List<String> labels, List<double> values}) operatingExpensesTrendBuckets(
    DateTimeRange range,
    String granularity,
  ) => _buckets(range, granularity, operatingExpensesDailyValue);

  /// Same buckets as [trendBuckets], but summed from the net-profit series.
  ({List<String> labels, List<double> values}) netProfitTrendBuckets(
    DateTimeRange range,
    String granularity,
  ) => _buckets(range, granularity, netProfitDailyValue);

  /// Four 6-hour readings as a share of a bucket's total, rotated bucket by
  /// bucket. The high is an estimate of the close rather than a ceiling, so
  /// the cycle mixes days that fade late with days that finish strong: with
  /// readings 1, 2, 3, 4 the high lands at 9 against a close of 10, while
  /// 4, 6, 8, 2 puts it at 26 against a close of 20.
  static const List<List<double>> _intraDayShapes = [
    [0.1, 0.2, 0.3, 0.4], // 1, 2, 3, 4 -> high 0.9 of close
    [0.2, 0.3, 0.4, 0.1], // 4, 6, 8, 2 -> high 1.3 of close
    [0.25, 0.25, 0.25, 0.25], // flat -> high equals close
    [0.15, 0.25, 0.3, 0.3], // high 1.0 of close
    [0.3, 0.3, 0.25, 0.15], // high 1.1 of close
    [0.2, 0.2, 0.25, 0.35], // high 0.85 of close
    [0.25, 0.35, 0.25, 0.15], // high 1.1 of close
    [0.15, 0.3, 0.25, 0.3], // high 0.95 of close
  ];

  /// OHLC per bucket for the candle view, built from the agreed formula. The
  /// bucket total is split into four 6-hour readings and then
  ///
  ///   Open  = third reading
  ///   High  = third reading x 2 + (first + second)
  ///   Low   = lowest of the four readings x 4
  ///   Close = the bucket total
  ///
  /// so readings 4, 6, 8, 2 (total 20) give 8 / 26 / 8 / 20. Because the four
  /// readings rotate through [_intraDayShapes], the high sits just around the
  /// close instead of always topping the chart: high = 1 + third - fourth of
  /// the close, so a day that ends strong drops the high below the close.
  List<({double open, double high, double low, double close})> candleBuckets(
    DateTimeRange range,
    String granularity,
    double Function(DateTime day) daily,
  ) {
    final start = DateUtils.dateOnly(range.start);
    final end = DateUtils.dateOnly(range.end);
    final result = <({double open, double high, double low, double close})>[];

    ({double open, double high, double low, double close}) ohlcFromTotal(
      double total,
    ) {
      final shape = _intraDayShapes[result.length % _intraDayShapes.length];
      final sum = shape.fold<double>(0, (a, b) => a + b);
      final q0 = total * shape[0] / sum;
      final q1 = total * shape[1] / sum;
      final q2 = total * shape[2] / sum;
      final q3 = total * shape[3] / sum;
      var lowest = q0;
      if (q1 < lowest) lowest = q1;
      if (q2 < lowest) lowest = q2;
      if (q3 < lowest) lowest = q3;
      return (
        open: q2,
        high: q2 * 2 + (q0 + q1),
        low: lowest * 4,
        close: total,
      );
    }

    if (granularity == 'Weekly') {
      var monday = DateTime(
        start.year,
        start.month,
        start.day + (DateTime.monday - start.weekday) % 7,
      );
      while (true) {
        final sunday = DateTime(monday.year, monday.month, monday.day + 6);
        if (sunday.isAfter(end)) break;
        var total = 0.0;
        for (var i = 0; i < 7; i++) {
          total += daily(DateTime(monday.year, monday.month, monday.day + i));
        }
        result.add(ohlcFromTotal(total));
        monday = DateTime(monday.year, monday.month, monday.day + 7);
      }
      return result;
    }

    if (granularity == 'Monthly') {
      var month = DateTime(start.year, start.month, 1);
      while (true) {
        final monthEnd = DateTime(month.year, month.month + 1, 0);
        if (monthEnd.isAfter(end)) break;
        var total = 0.0;
        for (var day = 1; day <= monthEnd.day; day++) {
          total += daily(DateTime(month.year, month.month, day));
        }
        result.add(ohlcFromTotal(total));
        month = DateTime(month.year, month.month + 1, 1);
      }
      return result;
    }

    var day = start;
    while (!day.isAfter(end)) {
      result.add(ohlcFromTotal(daily(day)));
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return result;
  }

  ({List<String> labels, List<double> values}) _buckets(
    DateTimeRange range,
    String granularity,
    double Function(DateTime day) daily, {
    bool average = false,
  }) {
    final start = DateUtils.dateOnly(range.start);
    final end = DateUtils.dateOnly(range.end);
    final labels = <String>[];
    final values = <double>[];

    // Amounts sum within a bucket; percentages average.
    double combine(List<double> samples) {
      if (samples.isEmpty) return 0;
      final total = samples.fold<double>(0, (sum, value) => sum + value);
      return average ? total / samples.length : total;
    }

    if (granularity == 'Weekly') {
      var monday = DateTime(
        start.year,
        start.month,
        start.day + (DateTime.monday - start.weekday) % 7,
      );
      while (true) {
        final sunday = DateTime(monday.year, monday.month, monday.day + 6);
        if (sunday.isAfter(end)) break;
        final samples = [
          for (var i = 0; i < 7; i++)
            daily(DateTime(monday.year, monday.month, monday.day + i)),
        ];
        labels.add('${monday.month}/${monday.day}');
        values.add(combine(samples));
        monday = DateTime(monday.year, monday.month, monday.day + 7);
      }
      return (labels: labels, values: values);
    }

    if (granularity == 'Monthly') {
      var month = DateTime(start.year, start.month, 1);
      while (true) {
        final monthEnd = DateTime(month.year, month.month + 1, 0);
        if (monthEnd.isAfter(end)) break;
        final samples = [
          for (var day = 1; day <= monthEnd.day; day++)
            daily(DateTime(month.year, month.month, day)),
        ];
        labels.add(monthAbbr[month.month - 1]);
        values.add(combine(samples));
        month = DateTime(month.year, month.month + 1, 1);
      }
      return (labels: labels, values: values);
    }

    var day = start;
    while (!day.isAfter(end)) {
      labels.add('${day.month}/${day.day}');
      values.add(daily(day));
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return (labels: labels, values: values);
  }

  /// Demo daily revenue in millions: ~0.5M a day, so thirty of them land on
  /// the 15M the KPI cards quote and each week totals 3.5M. Later years grow,
  /// so the year-on-year row is a real comparison rather than a flat copy.
  double dailyValue(DateTime d) {
    const pattern = [0.35, 0.55, 0.45, 0.65, 0.5, 0.4, 0.6];
    double raw(int day) => pattern[(day + d.month) % pattern.length];
    final growth = 1 + 0.12 * (d.year - 2026);
    return _rampedMonthValue(d, raw, _monthTotal(d, raw) * growth);
  }

  /// COGS daily values in millions. Repeats the old eight-day cost pattern
  /// across the range, so the November opening view keeps the same cost curve
  /// the page had before it gained date filters. Growth mirrors [dailyValue],
  /// so year-on-year ranges remain comparable.
  double cogsDailyValue(DateTime d) {
    const pattern = [0.7, 1.05, 0.9, 1.4, 1.75, 1.2, 2.1, 1.6];
    double raw(int day) => pattern[(day + d.month * 5) % pattern.length];
    final growth = 1 + 0.12 * (d.year - 2026);
    return _rampedMonthValue(d, raw, _monthTotal(d, raw) * growth);
  }

  // November 2026 anchors quoted by the COGS detail page.
  static const double _cogsBaseMonth = 28.5; // millions
  static const int _cogsBaseUnits = 1250;
  static const double _cogsBaseRatio = 62.2; // percent

  /// COGS figures for one comparison range. The page quotes 28.5M COGS,
  /// 1,250 units and a 62.2% ratio for November 2026, so the comparison is
  /// built from monthly anchors rather than the intra-month trend series:
  /// the trend chart deliberately keeps its original eight-day shape, while
  /// this table matches the figures shown on the cards.
  CogsPeriodStats cogsStatsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var cogs = 0.0;
    var units = 0.0;
    var revenue = 0.0;
    var day = start;
    while (!day.isAfter(end)) {
      final monthsBack = (2026 - day.year) * 12 + (11 - day.month);
      final daysInMonth = DateTime(day.year, day.month + 1, 0).day;
      final cogsForMonth = _cogsBaseMonth * _boundedGrowth(monthsBack, 1.096);
      final unitsForMonth = _cogsBaseUnits * _boundedGrowth(monthsBack, 1.136);
      final ratio = (_cogsBaseRatio + 1.8 * monthsBack).clamp(45.0, 90.0);
      final cogsForDay = cogsForMonth / daysInMonth;
      cogs += cogsForDay;
      units += unitsForMonth / daysInMonth;
      revenue += cogsForDay / (ratio / 100);
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return CogsPeriodStats(
      cogs: cogs,
      unitsSold: units.round(),
      revenue: revenue,
    );
  }

  /// Growth relative to the November 2026 demo month. The first year uses the
  /// page's month-over-month demo rates; beyond that it eases to the same 12%
  /// annual growth as [dailyValue], so wide date picks stay believable.
  double _boundedGrowth(int monthsBack, double monthlyRate) {
    final distance = monthsBack.abs();
    final months = distance < 12 ? distance : 12;
    final years = distance > 12 ? (distance - 12) / 12 : 0.0;
    final factor = math.pow(monthlyRate, -months) * math.pow(1.12, -years);
    return monthsBack >= 0 ? factor.toDouble() : 1 / factor;
  }

  /// Day-of-month ramp so daily values grow from the start of the month to the
  /// end (0.7x on the 1st to 1.3x on the last day). Its mean is exactly 1.0,
  /// so monthly totals stay the same after normalisation.
  double _dayRamp(DateTime d) {
    final daysInMonth = DateTime(d.year, d.month + 1, 0).day;
    if (daysInMonth <= 1) return 1;
    return 0.7 + 0.6 * (d.day - 1) / (daysInMonth - 1);
  }

  /// Sum of [rawValue] over every day of [d]'s month.
  double _monthTotal(DateTime d, double Function(int day) rawValue) {
    final daysInMonth = DateTime(d.year, d.month + 1, 0).day;
    var total = 0.0;
    for (var day = 1; day <= daysInMonth; day++) {
      total += rawValue(day);
    }
    return total;
  }

  /// The day-ramped value for [d], scaled so the month still adds up to
  /// [monthTotal]. The unramped shape is weighted by [_dayRamp] and then
  /// renormalised, so the series climbs from 0.7x on the 1st to 1.3x on the
  /// last day while every monthly anchor (15M revenue, 1,250 units, 7.7M net
  /// profit, ...) stays exactly where the cards quote it.
  double _rampedMonthValue(
    DateTime d,
    double Function(int day) rawValue,
    double monthTotal,
  ) {
    final daysInMonth = DateTime(d.year, d.month + 1, 0).day;
    var ramped = 0.0;
    for (var day = 1; day <= daysInMonth; day++) {
      ramped += rawValue(day) * _dayRamp(DateTime(d.year, d.month, day));
    }
    if (ramped == 0) return monthTotal / daysInMonth;
    return monthTotal * rawValue(d.day) * _dayRamp(d) / ramped;
  }

  /// Gross profit daily values in millions for the trend chart. The eight-day
  /// shape the page used before it gained range controls is kept, but each
  /// month is normalised so its total matches the 9.7M the cards quote for
  /// November 2026. Later ranges grow, so year-on-year views stay meaningful.
  double grossProfitDailyValue(DateTime d) {
    const pattern = [0.6, 0.9, 0.7, 1.1, 1.3, 0.8, 1.2, 1.5];
    double raw(int day) => pattern[(day - 1) % pattern.length];
    final monthsBack = (2026 - d.year) * 12 + (11 - d.month);
    final monthly = 9.7 * _boundedGrowth(monthsBack, 1.085);
    return _rampedMonthValue(d, raw, monthly);
  }

  /// Margin percentages for the trend chart. The eight-day shape from the
  /// page's original fixed chart is kept, but centred on each month's own
  /// pattern mean so every bucket averages the margin the cards quote: 34% for
  /// November 2026 and two points lower for each month further back (32% in
  /// October, and so on).
  double marginDailyValue(DateTime d) {
    const pattern = [30.0, 32.0, 34.0, 33.0, 35.0, 34.0, 33.0, 36.0];
    final monthsBack = (2026 - d.year) * 12 + (11 - d.month);
    final monthly = (_marginBaseOverall - 2.0 * monthsBack).clamp(5.0, 70.0);
    final daysInMonth = DateTime(d.year, d.month + 1, 0).day;
    var patternTotal = 0.0;
    for (var day = 1; day <= daysInMonth; day++) {
      patternTotal += pattern[(day - 1) % pattern.length];
    }
    final patternMean = patternTotal / daysInMonth;
    return monthly + pattern[(d.day - 1) % pattern.length] - patternMean;
  }

  /// Units sold per day for the trend chart. The eight-day shape the page used
  /// before it gained range controls is kept, normalised so each month totals
  /// the 1,250 units the cards quote for November 2026. Growth matches the COGS
  /// unit anchor, so October lands on the 1,100 the comparison used to show.
  double unitsDailyValue(DateTime d) {
    const pattern = [120.0, 160.0, 140.0, 180.0, 200.0, 150.0, 170.0, 190.0];
    double raw(int day) => pattern[(day - 1) % pattern.length];
    final monthsBack = (2026 - d.year) * 12 + (11 - d.month);
    final monthly = _cogsBaseUnits * _boundedGrowth(monthsBack, 1.136);
    return _rampedMonthValue(d, raw, monthly);
  }

  /// Transactions per day for the trend chart. The eight-day shape from the
  /// page's original fixed chart is kept, normalised so each month totals the
  /// 180 the cards quote for November 2026. Growth gives October the 160 the
  /// old comparison showed.
  double transactionsDailyValue(DateTime d) {
    const pattern = [6.0, 9.0, 7.0, 11.0, 13.0, 8.0, 10.0, 12.0];
    double raw(int day) => pattern[(day - 1) % pattern.length];
    final monthsBack = (2026 - d.year) * 12 + (11 - d.month);
    final monthly = _transactionsBaseCount * _boundedGrowth(monthsBack, 1.125);
    return _rampedMonthValue(d, raw, monthly);
  }

  /// AOV in thousands for the trend chart. The eight-day shape from the page's
  /// original fixed chart is kept, normalised so each month averages the
  /// 83.3K the cards quote for November 2026. October lands on 78.1K.
  double aovDailyValue(DateTime d) {
    const pattern = [80.0, 85.0, 82.0, 88.0, 90.0, 84.0, 86.0, 89.0];
    double raw(int day) => pattern[(day - 1) % pattern.length];
    final monthsBack = (2026 - d.year) * 12 + (11 - d.month);
    final monthly = 83.3 * _boundedGrowth(monthsBack, 1.0666);
    return _rampedMonthValue(d, raw, monthly);
  }

  /// Average units per transaction for the trend chart. The eight-day shape
  /// from the page's original fixed chart is kept, normalised so each month
  /// averages the 2.5 the cards quote for November 2026. October lands on 2.3.
  double avgUnitsDailyValue(DateTime d) {
    const pattern = [2.2, 2.5, 2.4, 2.7, 2.9, 2.5, 2.6, 2.8];
    double raw(int day) => pattern[(day - 1) % pattern.length];
    final monthsBack = (2026 - d.year) * 12 + (11 - d.month);
    final monthly = 2.5 * _boundedGrowth(monthsBack, 450 / 420);
    return _rampedMonthValue(d, raw, monthly);
  }

  /// Operating expenses per day for the trend chart. The eight-day shape from
  /// the page's original fixed chart is kept, normalised so each month totals
  /// the 2M the cards quote for November 2026. October lands on 1.8M.
  double operatingExpensesDailyValue(DateTime d) {
    const pattern = [0.3, 0.5, 0.4, 0.6, 0.5, 0.4, 0.6, 0.7];
    double raw(int day) => pattern[(day - 1) % pattern.length];
    final monthsBack = (2026 - d.year) * 12 + (11 - d.month);
    final monthly = 2.0 * _boundedGrowth(monthsBack, 2 / 1.8);
    return _rampedMonthValue(d, raw, monthly);
  }

  /// Net profit per day for the trend chart. The eight-day shape from the
  /// page's original fixed chart is kept, normalised so each month totals the
  /// 7.7M the cards quote for November 2026. October lands on 6.8M.
  double netProfitDailyValue(DateTime d) {
    const pattern = [0.9, 1.2, 1.0, 1.3, 1.5, 1.1, 1.4, 1.3];
    double raw(int day) => pattern[(day - 1) % pattern.length];
    final monthsBack = (2026 - d.year) * 12 + (11 - d.month);
    final monthly = 7.7 * _boundedGrowth(monthsBack, 7.7 / 6.8);
    return _rampedMonthValue(d, raw, monthly);
  }

  // November 2026 anchors quoted by the gross profit detail page.
  static const double _grossProfitBaseRevenue = 28.5; // millions
  static const double _grossProfitBaseProfit = 9.7; // millions

  /// Gross profit, revenue and COGS for one comparison range. November 2026
  /// is the page's 9.7M profit on 28.5M revenue; COGS is the remainder, so the
  /// three rows always add up. Profit uses the same growth as the trend series,
  /// which keeps a whole November range at exactly 9.7M.
  GrossProfitPeriodStats grossProfitStatsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var revenue = 0.0;
    var grossProfit = 0.0;
    var day = start;
    while (!day.isAfter(end)) {
      final monthsBack = (2026 - day.year) * 12 + (11 - day.month);
      final daysInMonth = DateTime(day.year, day.month + 1, 0).day;
      revenue +=
          _grossProfitBaseRevenue *
          _boundedGrowth(monthsBack, 1.096) /
          daysInMonth;
      grossProfit +=
          _grossProfitBaseProfit *
          _boundedGrowth(monthsBack, 1.085) /
          daysInMonth;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return GrossProfitPeriodStats(revenue: revenue, grossProfit: grossProfit);
  }

  // November 2026 margin anchors quoted by the margin detail page.
  static const double _marginBaseOverall = 34; // percent
  static const double _marginBaseElectronics = 31;
  static const double _marginBaseAccessories = 34;
  static const double _marginBaseComputer = 40;

  /// Margins for one comparison range, in percent. The overall figure comes
  /// from the same daily series as the trend, so November averages 34% and
  /// October 32%. Category rows use the November anchors and the drift the old
  /// "last month" column implied, so the defaults still read 31 -> 29,
  /// 34 -> 33 and 40 -> 38.
  MarginPeriodStats marginStatsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var overall = 0.0;
    var electronics = 0.0;
    var accessories = 0.0;
    var computer = 0.0;
    var days = 0;
    var day = start;
    while (!day.isAfter(end)) {
      final monthsBack = (2026 - day.year) * 12 + (11 - day.month);
      overall += marginDailyValue(day);
      electronics += (_marginBaseElectronics - 2.0 * monthsBack).clamp(
        5.0,
        70.0,
      );
      accessories += (_marginBaseAccessories - 1.0 * monthsBack).clamp(
        5.0,
        70.0,
      );
      computer += (_marginBaseComputer - 2.0 * monthsBack).clamp(5.0, 70.0);
      days++;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    if (days == 0) {
      return const MarginPeriodStats(
        overall: 0,
        electronics: 0,
        accessories: 0,
        computer: 0,
      );
    }
    return MarginPeriodStats(
      overall: overall / days,
      electronics: electronics / days,
      accessories: accessories / days,
      computer: computer / days,
    );
  }

  /// Units and best sellers for one comparison range. Unit totals come from the
  /// same daily series as the trend, so November rounds to 1,250 and October to
  /// 1,100. Best sellers rotate by month, reproducing Headphones -> Keyboard
  /// for those defaults while still giving later ranges a plausible answer.
  UnitsPeriodStats unitsStatsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var units = 0.0;
    var day = start;
    while (!day.isAfter(end)) {
      units += unitsDailyValue(day);
      day = DateTime(day.year, day.month, day.day + 1);
    }
    final monthsBack = (2026 - end.year) * 12 + (11 - end.month);
    const products = ['Headphones', 'Keyboard', 'Mouse'];
    return UnitsPeriodStats(
      unitsSold: units.round(),
      bestSellingProduct: products[monthsBack % products.length],
      bestSellingCategory: 'Electronics',
    );
  }

  // November 2026 anchors quoted by the transactions detail page.
  static const double _transactionsBaseCount = 180;
  static const double _transactionsBaseAvgValue = 0.0833; // millions
  static const double _transactionsBasePending = 12;

  /// Transaction count, average value and pending payments for one comparison
  /// range. Counts and values come from the same daily series as the trend;
  /// pending payments follow the 12 -> 15 month-over-month drift the page used
  /// to quote, so the November/October defaults remain unchanged.
  TransactionsPeriodStats transactionsStatsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var count = 0.0;
    var weightedValue = 0.0;
    var pending = 0.0;
    var day = start;
    while (!day.isAfter(end)) {
      final monthsBack = (2026 - day.year) * 12 + (11 - day.month);
      final daysInMonth = DateTime(day.year, day.month + 1, 0).day;
      final dayCount = transactionsDailyValue(day);
      final monthlyAvg =
          _transactionsBaseAvgValue * _boundedGrowth(monthsBack, 1.0666);
      count += dayCount;
      weightedValue += monthlyAvg * dayCount;
      final monthlyPending = (_transactionsBasePending + 3.0 * monthsBack)
          .clamp(0.0, 60.0);
      pending += monthlyPending / daysInMonth;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return TransactionsPeriodStats(
      transactions: count.round(),
      avgTransactionValue: count == 0 ? 0 : weightedValue / count,
      pendingPayments: pending.round(),
    );
  }

  // November 2026 anchors quoted by the AOV detail page.
  static const double _aovBaseRevenue = 15; // millions
  static const double _aovBaseTransactions = 180;

  /// AOV, revenue and transaction count for one comparison range. Revenue and
  /// count use the page's 15M / 180 anchors, so AOV stays consistent with
  /// revenue ÷ transactions and the November/October defaults read 83.3K and
  /// 78.1K.
  AovPeriodStats aovStatsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var revenue = 0.0;
    var transactions = 0.0;
    var day = start;
    while (!day.isAfter(end)) {
      final monthsBack = (2026 - day.year) * 12 + (11 - day.month);
      final daysInMonth = DateTime(day.year, day.month + 1, 0).day;
      revenue +=
          _aovBaseRevenue * _boundedGrowth(monthsBack, 15 / 14) / daysInMonth;
      transactions +=
          _aovBaseTransactions *
          _boundedGrowth(monthsBack, 180 / 179) /
          daysInMonth;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return AovPeriodStats(
      revenue: revenue,
      transactions: transactions.round(),
      aov: transactions == 0 ? 0 : revenue / transactions * 1000,
    );
  }

  // November 2026 anchors quoted by the avg-units detail page.
  static const double _avgUnitsBaseUnits = 450;
  static const double _avgUnitsBaseTransactions = 180;

  /// Average units, total units and transaction count for one comparison
  /// range. The November/October defaults reproduce 2.5 / 2.3, 450 / 420 and
  /// 180 / 182.
  AvgUnitsPeriodStats avgUnitsStatsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var units = 0.0;
    var transactions = 0.0;
    var day = start;
    while (!day.isAfter(end)) {
      final monthsBack = (2026 - day.year) * 12 + (11 - day.month);
      final daysInMonth = DateTime(day.year, day.month + 1, 0).day;
      units +=
          _avgUnitsBaseUnits *
          _boundedGrowth(monthsBack, 450 / 420) /
          daysInMonth;
      transactions +=
          _avgUnitsBaseTransactions *
          _boundedGrowth(monthsBack, 180 / 182) /
          daysInMonth;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return AvgUnitsPeriodStats(
      totalUnits: units.round(),
      transactions: transactions.round(),
      avgUnits: transactions == 0 ? 0 : units / transactions,
    );
  }

  // November 2026 anchors quoted by the operating-expenses detail page.
  static const double _opexBaseTotal = 2.0; // millions
  static const double _opexBaseRatio = 13.3; // percent

  /// Operating expenses, expense ratio and average daily expense for one
  /// comparison range. The November/October defaults reproduce 2M / 1.8M,
  /// 13.3% / 13.8% and 66.7K / 58.1K.
  OperatingExpensesPeriodStats operatingExpensesStatsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var total = 0.0;
    var ratio = 0.0;
    var days = 0;
    var day = start;
    while (!day.isAfter(end)) {
      final monthsBack = (2026 - day.year) * 12 + (11 - day.month);
      final daysInMonth = DateTime(day.year, day.month + 1, 0).day;
      total +=
          _opexBaseTotal * _boundedGrowth(monthsBack, 2 / 1.8) / daysInMonth;
      ratio += (_opexBaseRatio + 0.5 * monthsBack).clamp(5.0, 60.0);
      days++;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return OperatingExpensesPeriodStats(
      totalExpenses: total,
      expenseRatio: days == 0 ? 0 : ratio / days,
      avgDailyExpense: days == 0 ? 0 : total / days,
    );
  }

  // November 2026 anchors quoted by the net-profit detail page.
  static const double _netProfitBaseNet = 7.7; // millions
  static const double _netProfitBaseMargin = 27; // percent
  static const double _netProfitBaseRevenue = 28.5; // millions
  static const double _netProfitBaseCogs = 18.8; // millions
  static const double _netProfitBaseOpex = 2.0; // millions

  /// Net profit, margin, revenue, COGS and operating expenses for one
  /// comparison range. The November/October defaults reproduce 7.7M / 6.8M,
  /// 27% / 26%, 28.5M / 26M, 18.8M / 17.1M and 2M / 1.8M.
  NetProfitPeriodStats netProfitStatsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var netProfit = 0.0;
    var netMargin = 0.0;
    var revenue = 0.0;
    var cogs = 0.0;
    var opex = 0.0;
    var days = 0;
    var day = start;
    while (!day.isAfter(end)) {
      final monthsBack = (2026 - day.year) * 12 + (11 - day.month);
      final daysInMonth = DateTime(day.year, day.month + 1, 0).day;
      netProfit +=
          _netProfitBaseNet *
          _boundedGrowth(monthsBack, 7.7 / 6.8) /
          daysInMonth;
      netMargin += (_netProfitBaseMargin - 1.0 * monthsBack).clamp(5.0, 60.0);
      revenue +=
          _netProfitBaseRevenue *
          _boundedGrowth(monthsBack, 28.5 / 26) /
          daysInMonth;
      cogs +=
          _netProfitBaseCogs *
          _boundedGrowth(monthsBack, 18.8 / 17.1) /
          daysInMonth;
      opex +=
          _netProfitBaseOpex *
          _boundedGrowth(monthsBack, 2 / 1.8) /
          daysInMonth;
      days++;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return NetProfitPeriodStats(
      netProfit: netProfit,
      netMargin: days == 0 ? 0 : netMargin / days,
      revenue: revenue,
      cogs: cogs,
      operatingExpenses: opex,
    );
  }

  /// Totals for a range, all derived from the same demo daily series.
  SaleAnalysisStats statsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var revenue = 0.0;
    var day = start;
    while (!day.isAfter(end)) {
      revenue += dailyValue(day);
      day = DateTime(day.year, day.month, day.day + 1);
    }
    final days = end.difference(start).inDays + 1;
    // Six vouchers a day is the demo cadence behind the overview's 180 for
    // November, so transactions and AOV move with the range too.
    final transactions = days * 6;
    return SaleAnalysisStats(
      revenue: revenue,
      grossProfit: revenue * 0.4,
      transactions: transactions,
      aov: revenue * 1000000 / transactions,
    );
  }

  /// The same length immediately before the range. Whole calendar months line
  /// up with whole calendar months (November is compared with October), which
  /// is what finance teams expect; anything else uses the preceding N days.
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

  /// The same dates one year earlier, clamping 29 Feb to 28 Feb.
  DateTimeRange sameRangeLastYear(DateTimeRange r) =>
      DateTimeRange(start: shiftYear(r.start, -1), end: shiftYear(r.end, -1));

  DateTime shiftYear(DateTime d, int years) {
    final year = d.year + years;
    final lastDay = DateTime(year, d.month + 1, 0).day;
    return DateTime(year, d.month, d.day > lastDay ? lastDay : d.day);
  }

  bool isMonthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0).day == d.day;

  /// Millions, with thousands for small figures: 15.0M, 83.3K.
  String money(double millions) {
    if (millions.abs() >= 0.1) return '${millions.toStringAsFixed(1)}M';
    return '${(millions * 1000).toStringAsFixed(1)}K';
  }

  /// Percentage change with direction. A move smaller than a rounding step is
  /// shown as a dash instead of a misleading "↑ 0.0%".
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
    final from = '${monthAbbr[start.month - 1]} ${start.day}';
    if (start.year == end.year && start.month == end.month) {
      return '$from–${end.day}, ${end.year}';
    }
    if (start.year == end.year) {
      return '$from – ${monthAbbr[end.month - 1]} ${end.day}, ${end.year}';
    }
    return '$from, ${start.year} – '
        '${monthAbbr[end.month - 1]} ${end.day}, ${end.year}';
  }

  DateTime parseIso(String iso) {
    final parts = iso.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  String shortDate(String iso) {
    final d = parseIso(iso);
    return '${monthAbbr[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';
  }
}

/// Totals for one date range. Revenue and gross profit are in millions; AOV
/// is in MMK, because order values are quoted in thousands.
class SaleAnalysisStats {
  const SaleAnalysisStats({
    required this.revenue,
    required this.grossProfit,
    required this.transactions,
    required this.aov,
  });

  final double revenue;
  final double grossProfit;
  final int transactions;
  final double aov;
}

/// COGS totals for one comparison range. Amounts are in millions; average
/// cost is in MMK per unit.
class CogsPeriodStats {
  const CogsPeriodStats({
    required this.cogs,
    required this.unitsSold,
    required this.revenue,
  });

  final double cogs;
  final int unitsSold;
  final double revenue;

  double get avgCostPerUnit => unitsSold == 0 ? 0 : cogs * 1000000 / unitsSold;

  double get cogsRatio => revenue == 0 ? 0 : cogs / revenue * 100;
}

/// Gross profit figures for one comparison range. Amounts are in millions.
class GrossProfitPeriodStats {
  const GrossProfitPeriodStats({
    required this.revenue,
    required this.grossProfit,
  });

  final double revenue;
  final double grossProfit;

  double get cogs => revenue - grossProfit;

  double get margin => revenue == 0 ? 0 : grossProfit / revenue * 100;
}

/// Margin percentages for one comparison range. Every value is a percentage,
/// not an amount.
class MarginPeriodStats {
  const MarginPeriodStats({
    required this.overall,
    required this.electronics,
    required this.accessories,
    required this.computer,
  });

  final double overall;
  final double electronics;
  final double accessories;
  final double computer;
}

/// Units sold and best sellers for one comparison range.
class UnitsPeriodStats {
  const UnitsPeriodStats({
    required this.unitsSold,
    required this.bestSellingProduct,
    required this.bestSellingCategory,
  });

  final int unitsSold;
  final String bestSellingProduct;
  final String bestSellingCategory;
}

/// Transaction figures for one comparison range. The average value is in
/// millions, matching the amount unit used by the other comparison tables.
class TransactionsPeriodStats {
  const TransactionsPeriodStats({
    required this.transactions,
    required this.avgTransactionValue,
    required this.pendingPayments,
  });

  final int transactions;
  final double avgTransactionValue;
  final int pendingPayments;
}

/// AOV, revenue and transaction count for one comparison range. AOV is in
/// thousands; revenue is in millions.
class AovPeriodStats {
  const AovPeriodStats({
    required this.aov,
    required this.revenue,
    required this.transactions,
  });

  final double aov;
  final double revenue;
  final int transactions;
}

/// Average units per transaction, total units and transaction count for one
/// comparison range. The average is in units per transaction (a dimensionless
/// figure such as 2.5).
class AvgUnitsPeriodStats {
  const AvgUnitsPeriodStats({
    required this.avgUnits,
    required this.totalUnits,
    required this.transactions,
  });

  final double avgUnits;
  final int totalUnits;
  final int transactions;
}

/// Operating expenses for one comparison range. Total and daily average are in
/// millions; the ratio is a percentage.
class OperatingExpensesPeriodStats {
  const OperatingExpensesPeriodStats({
    required this.totalExpenses,
    required this.expenseRatio,
    required this.avgDailyExpense,
  });

  final double totalExpenses;
  final double expenseRatio;
  final double avgDailyExpense;
}

/// Net profit figures for one comparison range. All amounts are in millions;
/// the margin is a percentage.
class NetProfitPeriodStats {
  const NetProfitPeriodStats({
    required this.netProfit,
    required this.netMargin,
    required this.revenue,
    required this.cogs,
    required this.operatingExpenses,
  });

  final double netProfit;
  final double netMargin;
  final double revenue;
  final double cogs;
  final double operatingExpenses;
}
