import 'package:flutter/material.dart';

class Metric {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const Metric({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });
}

class TrendSeries {
  final String name;
  final Color color;
  final List<double> values;
  final List<String> dates;

  const TrendSeries(this.name, this.color, this.values, [this.dates = const []]);
}

class ProductItem {
  final String name;
  final String sold;
  final IconData icon;
  final String image;

  const ProductItem(this.name, this.sold, this.icon, {this.image = ''});
}

class DashboardData {
  final List<Metric> metrics;
  final List<TrendSeries> trendSeries;
  final List<ProductItem> mostBought;
  final List<ProductItem> leastBought;

  const DashboardData({
    required this.metrics,
    required this.trendSeries,
    required this.mostBought,
    required this.leastBought,
  });
}
