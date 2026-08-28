import 'package:flutter/material.dart';
import 'package:posfrontend/modules/dashboard/model/dashboard_models.dart';
import 'package:posfrontend/modules/dashboard/repository/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<DashboardData> getDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const DashboardData(
      metrics: [
        Metric(
          icon: Icons.view_in_ar,
          iconBg: Color(0xFFF3E8FF),
          iconColor: Color(0xFF6D28D9),
          label: 'Total Products',
          value: '1,245',
        ),
        Metric(
          icon: Icons.storefront,
          iconBg: Color(0xFFDCFCE7),
          iconColor: Color(0xFF16A34A),
          label: 'In Stock',
          value: '835',
        ),
        Metric(
          icon: Icons.shopping_cart,
          iconBg: Color(0xFFFEF3C7),
          iconColor: Color(0xFFCA8A04),
          label: 'Low Stock',
          value: '128',
        ),
        Metric(
          icon: Icons.attach_money,
          iconBg: Color(0xFFDBEAFE),
          iconColor: Color(0xFF2563EB),
          label: 'Total Sales',
          value: 'MMK 12,345',
        ),
      ],
      trendSeries: [
        TrendSeries('Electronics', Color(0xFF6D28D9), [40, 55, 48, 62, 58, 70, 78, 72]),
        TrendSeries('Fashion', Color(0xFF2563EB), [30, 42, 38, 50, 46, 55, 62, 58]),
        TrendSeries('Grocery', Color(0xFF16A34A), [70, 64, 76, 68, 74, 82, 72, 84]),
        TrendSeries('Home', Color(0xFFEA580C), [22, 28, 25, 34, 30, 40, 38, 42]),
      ],
      mostBought: [
        ProductItem('Wireless Earbuds', '256 sold', Icons.headphones),
        ProductItem('Smart Watch', '198 sold', Icons.watch),
        ProductItem('Backpack', '175 sold', Icons.backpack),
      ],
      leastBought: [
        ProductItem('Keyboard', '12 sold', Icons.keyboard),
        ProductItem('USB Cable', '15 sold', Icons.cable),
        ProductItem('Mouse Pad', '18 sold', Icons.touch_app),
      ],
    );
  }
}
