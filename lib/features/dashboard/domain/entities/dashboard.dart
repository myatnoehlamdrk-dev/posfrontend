import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_tables.dart';

class DashboardEntity extends Equatable {
  final List<MetricEntity> metrics;
  final DashboardStatsEntity stats;

  /// This calendar month's headline figures and last month's, from the API.
  final MonthSummaryEntity monthSummary;

  final List<CategoryDistributionEntity> categoryDistribution;
  final List<CategoryQuantityEntity> categoryQuantity;
  final List<ProductItemEntity> mostBought;
  final List<ProductItemEntity> leastBought;
  final List<ProductItemEntity> noBought;

  const DashboardEntity({
    required this.metrics,
    required this.stats,
    this.monthSummary = MonthSummaryEntity.empty,
    required this.categoryDistribution,
    required this.categoryQuantity,
    required this.mostBought,
    required this.leastBought,
    required this.noBought,
  });

  @override
  List<Object?> get props => [
    metrics,
    stats,
    monthSummary,
    categoryDistribution,
    categoryQuantity,
    mostBought,
    leastBought,
    noBought,
  ];
}

/// The headline figures a KPI tile shows.
///
/// Kept apart from [MetricEntity] because the two answer different questions:
/// a metric is *a* number worth a tile, while these are the numbers the rest
/// of the dashboard is read against — the stock percentages divide by
/// [totalProducts], the sales summary divides [totalSales] into orders and
/// average order value. Losing either would mean recomputing it in the widget.
class DashboardStatsEntity extends Equatable {
  /// All-time revenue: the sum of every sale's grand total.
  final int totalSales;

  final int totalProducts;

  /// Units sold across every sale, all time — the "Total Items Sold" figure.
  final int totalItemsSold;

  /// Active packages in this shop, and how many of them hold stock in each
  /// tier. Package stock is the summed available stock of its products.
  final int totalPackages;
  final int packagesInStock;
  final int packagesLowStock;
  final int packagesOutStock;

  /// Products with stock above the low-stock threshold. The three tiers are
  /// exclusive: [inStock] + [lowStock] + [outStock] equals [totalProducts].
  final int inStock;

  /// Products with stock between one and the low-stock threshold.
  final int lowStock;

  /// Products with no stock left.
  final int outStock;

  /// Sum of available stock units across all products.
  final int stockUnits;

  /// Number of sales (orders), not units.
  final int salesCount;

  /// Average grand total over the ten most recent sales.
  final int avgOrderValue;

  /// Units sold across every category inside the selected period. This is the
  /// only period-scoped figure here: everything else is all-time.
  final int itemsSold;

  const DashboardStatsEntity({
    required this.totalSales,
    required this.totalProducts,
    this.totalItemsSold = 0,
    this.totalPackages = 0,
    this.packagesInStock = 0,
    this.packagesLowStock = 0,
    this.packagesOutStock = 0,
    required this.inStock,
    required this.lowStock,
    required this.outStock,
    this.stockUnits = 0,
    required this.salesCount,
    required this.avgOrderValue,
    required this.itemsSold,
  });

  /// [value] as a share of the product range, for the stock-status bars.
  ///
  /// Guarded against a zero total so a shop with no products yet shows 0%
  /// rather than dividing by zero.
  double shareOf(int value) =>
      totalProducts <= 0 ? 0 : (value / totalProducts).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [
    totalSales,
    totalProducts,
    totalItemsSold,
    totalPackages,
    packagesInStock,
    packagesLowStock,
    packagesOutStock,
    inStock,
    lowStock,
    outStock,
    stockUnits,
    salesCount,
    avgOrderValue,
    itemsSold,
  ];
}

/// One headline figure measured over this calendar month and the whole month
/// before it, with the month-by-month line the tile draws.
class MonthFigureEntity extends Equatable {
  final double current;
  final double previous;

  /// One point per calendar month for the last year, oldest first, ending at
  /// [current]. The tile's trend line is this series.
  final List<double> series;

  const MonthFigureEntity({
    required this.current,
    required this.previous,
    this.series = const [],
  });

  /// The month-over-month change, ready for a trend badge.
  TrendEntity trend({bool inverted = false}) => TrendEntity.compare(
    current: current,
    previous: previous,
    inverted: inverted,
  );

  @override
  List<Object?> get props => [current, previous, series];
}

/// The calendar-month figures behind the Sales Summary card and the KPI tiles.
///
/// The cards still print all-time totals; "current", "previous" and "series"
/// are only what the arrow and the trend line read.
class MonthSummaryEntity extends Equatable {
  final MonthFigureEntity revenue;
  final MonthFigureEntity orders;
  final MonthFigureEntity avgOrderValue;
  final MonthFigureEntity itemsSold;
  final MonthFigureEntity products;
  final MonthFigureEntity lowStock;

  const MonthSummaryEntity({
    required this.revenue,
    required this.orders,
    required this.avgOrderValue,
    required this.itemsSold,
    required this.products,
    required this.lowStock,
  });

  static const empty = MonthSummaryEntity(
    revenue: MonthFigureEntity(current: 0, previous: 0),
    orders: MonthFigureEntity(current: 0, previous: 0),
    avgOrderValue: MonthFigureEntity(current: 0, previous: 0),
    itemsSold: MonthFigureEntity(current: 0, previous: 0),
    products: MonthFigureEntity(current: 0, previous: 0),
    lowStock: MonthFigureEntity(current: 0, previous: 0),
  );

  @override
  List<Object?> get props => [
    revenue,
    orders,
    avgOrderValue,
    itemsSold,
    products,
    lowStock,
  ];
}

/// Which windowed comparison a KPI tile draws under its figure.
///
/// The tiles are fixed copy written in the API model, so the key travels with
/// the tile and the screen resolves it against the trends the view model
/// built from the API's calendar-month figures.
enum MetricTrendKey { none, revenue, itemsSold, products, lowStock }

class MetricEntity extends Equatable {
  /// Resolved rather than stored as a code point: the four KPI tiles are
  /// fixed copy written here, not rows from the API, so there is nothing to
  /// serialise and the icon can stay typed.
  final IconData icon;
  final int iconBgValue;
  final int iconColorValue;
  final String label;
  final String value;

  /// Which table "View all" opens. Null for a tile that has no drill-down.
  final DashboardTableKey? tableKey;

  /// Which arrow this tile shows, if any.
  final MetricTrendKey trendKey;

  const MetricEntity({
    required this.icon,
    required this.iconBgValue,
    required this.iconColorValue,
    required this.label,
    required this.value,
    this.tableKey,
    this.trendKey = MetricTrendKey.none,
  });

  @override
  List<Object?> get props => [
    icon,
    iconBgValue,
    iconColorValue,
    label,
    value,
    tableKey,
    trendKey,
  ];
}

class CategoryDistributionEntity extends Equatable {
  final String category;
  final int productCount;
  final int colorValue;

  const CategoryDistributionEntity({
    required this.category,
    required this.productCount,
    required this.colorValue,
  });

  @override
  List<Object?> get props => [category, productCount, colorValue];
}

class CategoryQuantityEntity extends Equatable {
  final String category;
  final int totalQuantity;

  const CategoryQuantityEntity({
    required this.category,
    required this.totalQuantity,
  });

  @override
  List<Object?> get props => [category, totalQuantity];
}

class MonthlySalesEntity extends Equatable {
  final int month;
  final int total;
  final int cogs;
  final int units;
  final int transactions;
  final int purchases;

  /// Operation-fee cost computed from the shop's fee rules for this month.
  final double operationFee;

  const MonthlySalesEntity({
    required this.month,
    required this.total,
    this.cogs = 0,
    this.units = 0,
    this.transactions = 0,
    this.purchases = 0,
    this.operationFee = 0,
  });

  @override
  List<Object?> get props =>
      [month, total, cogs, units, transactions, purchases, operationFee];
}

/// One day of the sales chart: how many orders landed and what they summed to.
class SalesChartPointEntity extends Equatable {
  final DateTime date;
  final int orders;
  final int total;

  const SalesChartPointEntity({
    required this.date,
    required this.orders,
    required this.total,
  });

  @override
  List<Object?> get props => [date, orders, total];
}

/// Which way a figure moved between two windows of equal length.
///
/// The design's terms: up is bullish (green), down is bearish (red), and
/// unchanged is neither.
enum TrendDirection { up, down, flat }

/// A period-over-period change, drawn as the arrow beside a summary figure.
class TrendEntity extends Equatable {
  final TrendDirection direction;

  /// Percentage change, or null when the previous window held nothing to
  /// divide by — zero-to-something has no ratio, and `∞%` is not a number
  /// worth printing.
  final double? percent;

  /// True when *up* is the bad news — Low Stock Items, where more is worse.
  ///
  /// The arrow still follows the number (it went up, so it points up); only
  /// the colour and the bullish/bearish word flip, so a red `▲ 40%` reads as
  /// the warning the design draws it as.
  final bool inverted;

  const TrendEntity({
    required this.direction,
    required this.percent,
    this.inverted = false,
  });

  /// The change from [previous] to [current], both measured over the same
  /// length of window.
  ///
  /// A change smaller than 0.05% reads as flat: rounding a 0.01% wobble to
  /// "+0.0%" would show an arrow the data does not support.
  factory TrendEntity.compare({
    required double current,
    required double previous,
    bool inverted = false,
  }) {
    if (previous <= 0) {
      if (current <= 0) {
        return TrendEntity(
          direction: TrendDirection.flat,
          percent: 0,
          inverted: inverted,
        );
      }
      return TrendEntity(
        direction: TrendDirection.up,
        percent: null,
        inverted: inverted,
      );
    }

    final change = (current - previous) / previous * 100;
    final direction = change > 0.05
        ? TrendDirection.up
        : change < -0.05
        ? TrendDirection.down
        : TrendDirection.flat;
    return TrendEntity(
      direction: direction,
      percent: change,
      inverted: inverted,
    );
  }

  bool get isBullish =>
      (direction == TrendDirection.up) != inverted &&
      direction != TrendDirection.flat;
  bool get isBearish => isBullish == false && direction != TrendDirection.flat;

  @override
  List<Object?> get props => [direction, percent, inverted];
}

/// The changes shown on the Sales Summary card and the four KPI tiles, or
/// null on the screen when the comparison could not be fetched at all.
class SummaryTrendsEntity extends Equatable {
  final TrendEntity revenue;
  final TrendEntity orders;
  final TrendEntity avgOrderValue;
  final TrendEntity itemsSold;

  /// Product count and low-stock count, both compared with the end of last
  /// month. Low stock is inverted: more of it is worse.
  final TrendEntity products;
  final TrendEntity lowStock;

  const SummaryTrendsEntity({
    required this.revenue,
    required this.orders,
    required this.avgOrderValue,
    required this.itemsSold,
    required this.products,
    required this.lowStock,
  });

  /// The change behind one KPI tile, keyed by the tile's [MetricTrendKey].
  TrendEntity? forMetric(MetricTrendKey key) => switch (key) {
    MetricTrendKey.revenue => revenue,
    MetricTrendKey.itemsSold => itemsSold,
    MetricTrendKey.products => products,
    MetricTrendKey.lowStock => lowStock,
    MetricTrendKey.none => null,
  };

  @override
  List<Object?> get props => [
    revenue,
    orders,
    avgOrderValue,
    itemsSold,
    products,
    lowStock,
  ];
}

class ProductItemEntity extends Equatable {
  final String name;
  final String sold;

  /// Fallback shown when the product has no image. Resolved rather than kept
  /// as a code point so the widget never has to rebuild an [IconData] from
  /// two fields — which is a non-constant argument to a const constructor,
  /// and lints.
  final IconData icon;
  final String image;

  const ProductItemEntity({
    required this.name,
    required this.sold,
    required this.icon,
    required this.image,
  });

  @override
  List<Object?> get props => [name, sold, icon, image];
}
