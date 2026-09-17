import 'package:equatable/equatable.dart';

class DashboardEntity extends Equatable {
  final List<MetricEntity> metrics;
  final List<TrendSeriesEntity> trendSeries;
  final List<ProductItemEntity> mostBought;
  final List<ProductItemEntity> leastBought;

  const DashboardEntity({
    required this.metrics,
    required this.trendSeries,
    required this.mostBought,
    required this.leastBought,
  });

  @override
  List<Object?> get props => [metrics, trendSeries, mostBought, leastBought];
}

class MetricEntity extends Equatable {
  final String iconCodePoint;
  final String iconFontFamily;
  final int iconBgValue;
  final int iconColorValue;
  final String label;
  final String value;

  const MetricEntity({
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.iconBgValue,
    required this.iconColorValue,
    required this.label,
    required this.value,
  });

  @override
  List<Object?> get props => [
        iconCodePoint,
        iconFontFamily,
        iconBgValue,
        iconColorValue,
        label,
        value,
      ];
}

class TrendSeriesEntity extends Equatable {
  final String name;
  final int colorValue;
  final List<double> values;
  final List<String> dates;

  const TrendSeriesEntity({
    required this.name,
    required this.colorValue,
    required this.values,
    required this.dates,
  });

  @override
  List<Object?> get props => [name, colorValue, values, dates];
}

class ProductItemEntity extends Equatable {
  final String name;
  final String sold;
  final int iconCodePoint;
  final String iconFontFamily;
  final String image;

  const ProductItemEntity({
    required this.name,
    required this.sold,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.image,
  });

  @override
  List<Object?> get props => [name, sold, iconCodePoint, iconFontFamily, image];
}
