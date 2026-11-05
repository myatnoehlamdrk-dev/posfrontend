import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/core/extensions/map_json_extensions.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_tables.dart';

class DashboardApiModel {
  final List<MetricEntity> metrics;
  final DashboardStatsEntity stats;
  final List<CategoryDistributionEntity> categoryDistribution;
  final List<CategoryQuantityEntity> categoryQuantity;
  final List<ProductItemEntity> mostBought;
  final List<ProductItemEntity> leastBought;
  final List<ProductItemEntity> noBought;

  const DashboardApiModel({
    required this.metrics,
    required this.stats,
    required this.categoryDistribution,
    required this.categoryQuantity,
    required this.mostBought,
    required this.leastBought,
    required this.noBought,
  });

/// One colour per category, assigned in order, and used by the product
  /// distribution pie chart.
///
/// Sixteen entries rather than eight, and spaced so no two neighbours are close
  /// enough to read as the same slice. The brand purple is deliberately not
  /// here: this chart is categorical, and a second brand-purple slice sitting
  /// beside another purple is exactly the confusion it is meant to avoid.
static const List<int> _categoryColors = [
  0xFF6D28D9, // violet
  0xFF14B8A6, // teal
  0xFFE53935, // red
  0xFFFB8C00, // orange
  0xFF43A047, // green
  0xFF3B82F6, // blue
  0xFFD97706, // amber
  0xFFDB2777, // pink
  0xFF8B5CF6, // light violet
  0xFF0891B2, // cyan
  0xFF65A30D, // lime
  0xFF9333EA, // fuchsia
  0xFF0EA5E9, // sky
  0xFFB45309, // brown
  0xFF64748B, // slate
  0xFFBE185D, // rose
];

  factory DashboardApiModel.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};
    final distRes = json['category_distribution'] as List<dynamic>? ?? [];
    final catQtyRes = json['category_quantity'] as List<dynamic>? ?? [];
    final topRes = json['top_products'] as List<dynamic>? ?? [];
    final leastRes = json['least_products'] as List<dynamic>? ?? [];
    final noBoughtRes = json['no_bought_products'] as List<dynamic>? ?? [];

    final totalProducts = statsJson.integer('total_products');
    final inStock = statsJson.integer('in_stock');
    final lowStock = statsJson.integer('low_stock_count');
    final totalSales = statsJson.integer('total_sales');
    final outStock = statsJson.integer('out_stock_count');
    final salesCount = statsJson.integer('sales_count');
    final avgOrderValue = statsJson.integer('avg_sale_last10');

    final categoryQuantity = catQtyRes.map<CategoryQuantityEntity>((e) {
      final item = e as Map<String, dynamic>;
      return CategoryQuantityEntity(
        category: item.str('category_name', 'Unknown'),
        totalQuantity: item.integer('total_quantity'),
      );
    }).toList();

    // The only period-scoped figure in the payload: the backend sums sale
    // lines per category over `days`, so folding the categories back together
    // gives units sold for whichever window the user picked.
    final itemsSold = categoryQuantity.fold<int>(
      0,
      (sum, e) => sum + e.totalQuantity,
    );

    final dashboardStats = DashboardStatsEntity(
      totalSales: totalSales,
      totalProducts: totalProducts,
      inStock: inStock,
      lowStock: lowStock,
      outStock: outStock,
      salesCount: salesCount,
      avgOrderValue: avgOrderValue,
      itemsSold: itemsSold,
    );

    // Four tiles, in the order the design reads them. The old set carried a
    // four-row breakdown under each headline figure; that detail now lives in
    // the Stock Status panel, which draws the same tiers as bars and is
    // visible without opening a tile.
    final metrics = [
      MetricEntity(
        icon: Icons.bar_chart_rounded,
        iconBgValue: 0xFFF3E8FF,
        iconColorValue: 0xFF7952DB,
        tableKey: DashboardTableKey.sales,
        trendKey: MetricTrendKey.revenue,
        label: 'Total Sales',
        value: 'MMK ${totalSales.withCommas()}',
      ),
      MetricEntity(
        icon: Icons.inventory_2_outlined,
        iconBgValue: 0xFFDCFCE7,
        iconColorValue: 0xFF16A34A,
        tableKey: DashboardTableKey.products,
        trendKey: MetricTrendKey.products,
        label: 'Total Products',
        value: totalProducts.withCommas(),
      ),
      MetricEntity(
        icon: Icons.shopping_cart_outlined,
        iconBgValue: 0xFFDBEAFE,
        iconColorValue: 0xFF3B82F6,
        tableKey: DashboardTableKey.sales,
        trendKey: MetricTrendKey.itemsSold,
        label: 'Total Items Sold',
        value: itemsSold.withCommas(),
      ),
      MetricEntity(
        icon: Icons.warning_amber_outlined,
        iconBgValue: 0xFFFEF3C7,
        iconColorValue: 0xFFF59E0B,
        tableKey: DashboardTableKey.lowStock,
        trendKey: MetricTrendKey.lowStock,
        label: 'Low Stock Items',
        value: lowStock.withCommas(),
      ),
    ];

    final categoryDistribution = <CategoryDistributionEntity>[];
    for (var i = 0; i < distRes.length; i++) {
      final item = distRes[i] as Map<String, dynamic>;
      final count = item.integer('product_count');
      if (count <= 0) continue;
      categoryDistribution.add(
        CategoryDistributionEntity(
          category: item.str('category_name', 'Unknown'),
          productCount: count,
          // Coloured by position in the list being built, not by `i`. `i` counts
          // every row in the response, including the ones dropped just above for
          // having no products, so two slices could land on the same entry of
          // the palette — which is how Food and Home came out the same colour.
          colorValue: _categoryColors[
            categoryDistribution.length % _categoryColors.length
          ],
        ),
      );
    }

    final mostBought = topRes.map<ProductItemEntity>((e) {
      final item = e as Map<String, dynamic>;
      final name = item['product_name'] as String? ?? 'Unknown';
      final qty = item.integer('total_quantity');
      final image = resolveMediaUrl(item['product_image'] as String?) ?? '';
      return ProductItemEntity(
        name: name,
        sold: '$qty sold',
        icon: Icons.inventory_2_outlined,
        image: image,
      );
    }).toList();

    final leastBought = leastRes.map<ProductItemEntity>((e) {
      final item = e as Map<String, dynamic>;
      final name = item['product_name'] as String? ?? 'Unknown';
      final qty = item.integer('total_quantity');
      final image = resolveMediaUrl(item['product_image'] as String?) ?? '';
      return ProductItemEntity(
        name: name,
        sold: '$qty sold',
        icon: Icons.inventory_2_outlined,
        image: image,
      );
    }).toList();

    final noBought = noBoughtRes.map<ProductItemEntity>((e) {
      final item = e as Map<String, dynamic>;
      final name = item['product_name'] as String? ?? 'Unknown';
      final image = resolveMediaUrl(item['product_image'] as String?) ?? '';
      return ProductItemEntity(
        name: name,
        sold: 'Never sold',
        icon: Icons.inventory_2_outlined,
        image: image,
      );
    }).toList();

    return DashboardApiModel(
      metrics: metrics,
      stats: dashboardStats,
      categoryDistribution: categoryDistribution,
      categoryQuantity: categoryQuantity,
      mostBought: mostBought,
      leastBought: leastBought,
      noBought: noBought,
    );
  }

  DashboardEntity toEntity() {
    return DashboardEntity(
      metrics: metrics,
      stats: stats,
      categoryDistribution: categoryDistribution,
      categoryQuantity: categoryQuantity,
      mostBought: mostBought,
      leastBought: leastBought,
      noBought: noBought,
    );
  }
}
