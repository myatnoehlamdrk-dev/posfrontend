import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/dashboard/model/dashboard_models.dart';
import 'package:posfrontend/modules/dashboard/repository/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<DashboardData> getDashboardData({int days = 30}) async {
    final dio = ApiClient.create();
    final resp = await dio.get('/api/dashboard/all', queryParameters: {'days': days});
    final data = resp.data as Map<String, dynamic>;

    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final trendRes = data['category_trend'] as List<dynamic>? ?? [];
    final topRes = data['top_products'] as List<dynamic>? ?? [];
    final leastRes = data['least_products'] as List<dynamic>? ?? [];

    final totalProducts = _toInt(stats['total_products']);
    final inStock = _toInt(stats['in_stock']);
    final lowStock = _toInt(stats['low_stock_count']);
    final totalSales = _toInt(stats['total_sales']);

    return DashboardData(
      metrics: [
        Metric(
          icon: Icons.view_in_ar,
          iconBg: const Color(0xFFF3E8FF),
          iconColor: const Color(0xFF6D28D9),
          label: 'Total Products',
          value: _formatNumber(totalProducts),
        ),
        Metric(
          icon: Icons.storefront,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          label: 'In Stock',
          value: _formatNumber(inStock),
        ),
        Metric(
          icon: Icons.shopping_cart,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFCA8A04),
          label: 'Low Stock',
          value: _formatNumber(lowStock),
        ),
        Metric(
          icon: Icons.attach_money,
          iconBg: const Color(0xFFDBEAFE),
          iconColor: const Color(0xFF2563EB),
          label: 'Total Sales',
          value: 'MMK ${_formatNumber(totalSales)}',
        ),
      ],
      trendSeries: _parseTrendSeries(trendRes),
      mostBought: topRes.map((e) => _parseProductItem(e)).toList(),
      leastBought: leastRes.map((e) => _parseProductItem(e)).toList(),
    );
  }

  static const List<Color> _categoryColors = [
    Color(0xFF6D28D9),
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFEA580C),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFCA8A04),
  ];

  List<TrendSeries> _parseTrendSeries(List<dynamic> data) {
    final series = <TrendSeries>[];
    for (var i = 0; i < data.length; i++) {
      final item = data[i] as Map<String, dynamic>;
      final values = (item['values'] as List<dynamic>?)
              ?.map((e) => _toDouble(e))
              .toList() ??
          [];
      final dates = (item['dates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      series.add(TrendSeries(
        item['category'] as String? ?? 'Unknown',
        _categoryColors[i % _categoryColors.length],
        values,
        dates,
      ));
    }
    return series;
  }

  ProductItem _parseProductItem(Map<String, dynamic> item) {
    final name = item['product_name'] as String? ?? 'Unknown';
    final qty = _toInt(item['total_quantity']);
    final image = item['product_image'] as String? ?? '';
    return ProductItem(name, '$qty sold', Icons.inventory_2, image: image);
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _formatNumber(num n) {
    final s = n.toInt().toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
