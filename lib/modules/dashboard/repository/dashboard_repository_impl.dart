import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/core/extensions/map_json_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/dashboard/model/dashboard_models.dart';
import 'package:posfrontend/modules/dashboard/repository/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<DashboardData> getDashboardData({int days = 30, CancelToken? cancelToken}) async {
    final dio = ApiClient.create();
    final resp = await dio.get('/api/dashboard/all', queryParameters: {'days': days}, cancelToken: cancelToken);
    final data = resp.data as Map<String, dynamic>;

    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final trendRes = data['category_trend'] as List<dynamic>? ?? [];
    final topRes = data['top_products'] as List<dynamic>? ?? [];
    final leastRes = data['least_products'] as List<dynamic>? ?? [];

    final totalProducts = stats.integer('total_products');
    final inStock = stats.integer('in_stock');
    final lowStock = stats.integer('low_stock_count');
    final totalSales = stats.integer('total_sales');

    return DashboardData(
      metrics: [
        Metric(
          icon: Icons.view_in_ar,
          iconBg: const Color(0xFFF3E8FF),
          iconColor: const Color(0xFF6D28D9),
          label: 'Total Products',
          value: totalProducts.withCommas(),
        ),
        Metric(
          icon: Icons.storefront,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          label: 'In Stock',
          value: inStock.withCommas(),
        ),
        Metric(
          icon: Icons.shopping_cart,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFCA8A04),
          label: 'Low Stock',
          value: lowStock.withCommas(),
        ),
        Metric(
          icon: Icons.attach_money,
          iconBg: const Color(0xFFDBEAFE),
          iconColor: const Color(0xFF2563EB),
          label: 'Total Sales',
          value: 'MMK ${totalSales.withCommas()}',
        ),
      ],
      trendSeries: _parseTrendSeries(trendRes),
      mostBought: topRes.map((e) => _parseProductItem(e)).toList(),
      leastBought: leastRes.map((e) => _parseProductItem(e)).toList(),
    );
  }

  static const List<Color> _categoryColors = [
    Color(0xFF6D28D9), // purple
    Color(0xFF2563EB), // blue
    Color(0xFF16A34A), // green
    Color(0xFFEA580C), // orange
    Color(0xFFDC2626), // red
    Color(0xFF0891B2), // teal
    Color(0xFFCA8A04), // yellow/amber
    Color(0xFFE11D48), // pink
    Color(0xFF059669), // emerald
    Color(0xFFD97706), // amber
    Color(0xFF7C3AED), // violet
    Color(0xFF0284C7), // sky blue
  ];

  List<TrendSeries> _parseTrendSeries(List<dynamic> data) {
    final series = <TrendSeries>[];
    for (var i = 0; i < data.length; i++) {
      final item = data[i] as Map<String, dynamic>;
      final values = (item['values'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [];
      final dates = (item['dates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final category = item['category'] as String? ?? 'Unknown';
      series.add(TrendSeries(
        category,
        _categoryColors[i % _categoryColors.length],
        values,
        dates,
      ));
    }
    return series;
  }

  ProductItem _parseProductItem(Map<String, dynamic> item) {
    final name = item['product_name'] as String? ?? 'Unknown';
    final qty = item.integer('total_quantity');
    final image = item['product_image'] as String? ?? '';
    return ProductItem(name, '$qty sold', Icons.inventory_2, image: image);
  }
}
