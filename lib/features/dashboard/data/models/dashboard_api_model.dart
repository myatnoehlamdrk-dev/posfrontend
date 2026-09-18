import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/core/extensions/map_json_extensions.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';

class DashboardApiModel {
  final List<MetricEntity> metrics;
  final List<TrendSeriesEntity> trendSeries;
  final List<ProductItemEntity> mostBought;
  final List<ProductItemEntity> leastBought;

  const DashboardApiModel({
    required this.metrics,
    required this.trendSeries,
    required this.mostBought,
    required this.leastBought,
  });

  static const List<int> _categoryColors = [
    0xFF6D28D9,
    0xFF14B8A6,
    0xFFE53935,
    0xFFFB8C00,
    0xFF43A047,
    0xFF3B82F6,
    0xFFD97706,
    0xFF8B5CF6,
  ];

  factory DashboardApiModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final trendRes = json['category_trend'] as List<dynamic>? ?? [];
    final topRes = json['top_products'] as List<dynamic>? ?? [];
    final leastRes = json['least_products'] as List<dynamic>? ?? [];

    final totalProducts = stats.integer('total_products');
    final inStock = stats.integer('in_stock');
    final lowStock = stats.integer('low_stock_count');
    final totalSales = stats.integer('total_sales');

    final metrics = [
      MetricEntity(
        iconCodePoint: '0xe04c',
        iconFontFamily: 'MaterialIcons',
        iconBgValue: 0xFFDCFCE7,
        iconColorValue: 0xFF16A34A,
        label: 'Total Products',
        value: totalProducts.withCommas(),
      ),
      MetricEntity(
        iconCodePoint: '0xe5ca',
        iconFontFamily: 'MaterialIcons',
        iconBgValue: 0xFFDBEAFE,
        iconColorValue: 0xFF3B82F6,
        label: 'In Stock',
        value: inStock.withCommas(),
      ),
      MetricEntity(
        iconCodePoint: '0xe002',
        iconFontFamily: 'MaterialIcons',
        iconBgValue: 0xFFFEF3C7,
        iconColorValue: 0xFFF59E0B,
        label: 'Low Stock',
        value: lowStock.withCommas(),
      ),
      MetricEntity(
        iconCodePoint: '0xe227',
        iconFontFamily: 'MaterialIcons',
        iconBgValue: 0xFFF3E8FF,
        iconColorValue: 0xFF8B5CF6,
        label: 'Total Sales',
        value: 'MMK ${totalSales.withCommas()}',
      ),
    ];

    final trendSeries = <TrendSeriesEntity>[];
    for (var i = 0; i < trendRes.length; i++) {
      final item = trendRes[i] as Map<String, dynamic>;
      final values = (item['values'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [];
      final dates = (item['dates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final name = item['category'] as String? ?? 'Unknown';
      trendSeries.add(TrendSeriesEntity(
        name: name,
        colorValue: _categoryColors[i % _categoryColors.length],
        values: values,
        dates: dates,
      ));
    }

    final mostBought = topRes.map<ProductItemEntity>((e) {
      final item = e as Map<String, dynamic>;
      final name = item['product_name'] as String? ?? 'Unknown';
      final qty = item.integer('total_quantity');
      final image = item['product_image'] as String? ?? '';
      return ProductItemEntity(
        name: name,
        sold: '$qty sold',
        iconCodePoint: 0xe04c,
        iconFontFamily: 'MaterialIcons',
        image: image,
      );
    }).toList();

    final leastBought = leastRes.map<ProductItemEntity>((e) {
      final item = e as Map<String, dynamic>;
      final name = item['product_name'] as String? ?? 'Unknown';
      final qty = item.integer('total_quantity');
      final image = item['product_image'] as String? ?? '';
      return ProductItemEntity(
        name: name,
        sold: '$qty sold',
        iconCodePoint: 0xe04c,
        iconFontFamily: 'MaterialIcons',
        image: image,
      );
    }).toList();

    return DashboardApiModel(
      metrics: metrics,
      trendSeries: trendSeries,
      mostBought: mostBought,
      leastBought: leastBought,
    );
  }

  DashboardEntity toEntity() {
    return DashboardEntity(
      metrics: metrics,
      trendSeries: trendSeries,
      mostBought: mostBought,
      leastBought: leastBought,
    );
  }
}
