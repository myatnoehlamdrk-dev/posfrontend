import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/dashboard/model/dashboard_models.dart';
import 'package:posfrontend/modules/dashboard/repository/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  static const int _lowStockMax = 9;

  @override
  Future<DashboardData> getDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final stocks = await _fetchAllProductStocks();
    final totalSales = await _fetchAllSalesTotal();

    final totalProducts = stocks.length;
    final inStock = stocks.where((s) => s > 0).length;
    final lowStock = stocks.where((s) => s > 0 && s <= _lowStockMax).length;

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
      trendSeries: const [
        TrendSeries('Electronics', Color(0xFF6D28D9), [40, 55, 48, 62, 58, 70, 78, 72]),
        TrendSeries('Fashion', Color(0xFF2563EB), [30, 42, 38, 50, 46, 55, 62, 58]),
        TrendSeries('Grocery', Color(0xFF16A34A), [70, 64, 76, 68, 74, 82, 72, 84]),
        TrendSeries('Home', Color(0xFFEA580C), [22, 28, 25, 34, 30, 40, 38, 42]),
      ],
      mostBought: const [
        ProductItem('Wireless Earbuds', '256 sold', Icons.headphones),
        ProductItem('Smart Watch', '198 sold', Icons.watch),
        ProductItem('Backpack', '175 sold', Icons.backpack),
      ],
      leastBought: const [
        ProductItem('Keyboard', '12 sold', Icons.keyboard),
        ProductItem('USB Cable', '15 sold', Icons.cable),
        ProductItem('Mouse Pad', '18 sold', Icons.touch_app),
      ],
    );
  }

  Future<List<int>> _fetchAllProductStocks() async {
    try {
      final dio = ApiClient.create();
      final stocks = <int>[];
      int page = 1;
      int lastPage = 1;

      do {
        final resp = await dio.get('/api/products', queryParameters: {'page': page});
        final data = resp.data;

        final items = _extractList(data);
        for (final item in items) {
          if (item is Map) {
            final stock = (item['stock'] as num?)?.toInt() ?? 0;
            stocks.add(stock);
          }
        }

        if (data is Map) {
          final meta = data['meta'];
          if (meta is Map) {
            lastPage = (meta['last_page'] as num?)?.toInt() ?? 1;
          }
        }
        page++;
      } while (page <= lastPage);

      return stocks;
    } catch (_) {
      return [];
    }
  }

  Future<int> _fetchAllSalesTotal() async {
    try {
      final dio = ApiClient.create();
      int totalSales = 0;
      int page = 1;
      int lastPage = 1;

      do {
        final resp = await dio.get('/api/sales', queryParameters: {'page': page});
        final data = resp.data;

        final items = _extractList(data);
        for (final item in items) {
          if (item is Map) {
            final grandTotal = (item['grandTotal'] as num?)?.toDouble() ?? 0.0;
            totalSales += grandTotal.round();
          }
        }

        if (data is Map) {
          final meta = data['meta'];
          if (meta is Map) {
            lastPage = (meta['last_page'] as num?)?.toInt() ?? 1;
          }
        }
        page++;
      } while (page <= lastPage);

      return totalSales;
    } catch (_) {
      return 0;
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  String _formatNumber(num n) {
    final s = n.toInt().toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
