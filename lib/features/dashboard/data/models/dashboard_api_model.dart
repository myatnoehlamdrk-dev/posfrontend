import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/core/extensions/map_json_extensions.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_tables.dart';

class DashboardApiModel {
  final List<MetricEntity> metrics;
  final List<CategoryDistributionEntity> categoryDistribution;
  final List<CategoryQuantityEntity> categoryQuantity;
  final List<ProductItemEntity> mostBought;
  final List<ProductItemEntity> leastBought;
  final List<ProductItemEntity> noBought;

  const DashboardApiModel({
    required this.metrics,
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
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final distRes = json['category_distribution'] as List<dynamic>? ?? [];
    final catQtyRes = json['category_quantity'] as List<dynamic>? ?? [];
    final topRes = json['top_products'] as List<dynamic>? ?? [];
    final leastRes = json['least_products'] as List<dynamic>? ?? [];
    final noBoughtRes = json['no_bought_products'] as List<dynamic>? ?? [];

    final totalProducts = stats.integer('total_products');
    final inStock = stats.integer('in_stock');
    final lowStock = stats.integer('low_stock_count');
    final totalSales = stats.integer('total_sales');

    final totalCategories = stats.integer('total_categories');
    final totalPackages = stats.integer('total_packages');
    final brandCount = stats.integer('brand_count');
    final categoryless = stats.integer('categoryless_products');
    final highStock = stats.integer('high_stock_count');
    final midStock = stats.integer('mid_stock_count');
    final outStock = stats.integer('out_stock_count');
    final inCart = stats.integer('in_cart_count');
    final salesCount = stats.integer('sales_count');
    final avgSale = stats.integer('avg_sale_last10');
    final avgProducts = stats.integer('avg_products_last10');

    final metrics = [
      MetricEntity(
        iconCodePoint: '0xe04c',
        iconFontFamily: 'MaterialIcons',
        iconBgValue: 0xFFDCFCE7,
        iconColorValue: 0xFF16A34A,
        tableKey: DashboardTableKey.products,
        label: 'Total Products',
        value: totalProducts.compact(),
        details: [
          MetricDetailEntity(
            label: 'Categories',
            value: totalCategories.compact(),
          ),
          MetricDetailEntity(label: 'Packages', value: totalPackages.compact()),
          MetricDetailEntity(label: 'Brands', value: brandCount.compact()),
          MetricDetailEntity(
            label: 'No Category',
            value: categoryless.compact(),
          ),
        ],
      ),
      MetricEntity(
        iconCodePoint: '0xe5ca',
        iconFontFamily: 'MaterialIcons',
        iconBgValue: 0xFFDBEAFE,
        iconColorValue: 0xFF3B82F6,
        tableKey: DashboardTableKey.inStock,
        label: 'In Stock',
        value: inStock.compact(),
        details: [
          MetricDetailEntity(label: 'High', value: highStock.compact()),
          MetricDetailEntity(label: 'Mid', value: midStock.compact()),
          MetricDetailEntity(label: 'Low', value: lowStock.compact()),
          MetricDetailEntity(label: 'Out', value: outStock.compact()),
        ],
      ),
      MetricEntity(
        iconCodePoint: '0xe002',
        iconFontFamily: 'MaterialIcons',
        iconBgValue: 0xFFFEF3C7,
        iconColorValue: 0xFFF59E0B,
        tableKey: DashboardTableKey.lowStock,
        label: 'Low Stock',
        value: lowStock.compact(),
        details: [
          MetricDetailEntity(label: 'High', value: highStock.compact()),
          MetricDetailEntity(label: 'Mid', value: midStock.compact()),
          MetricDetailEntity(label: 'Low', value: lowStock.compact()),
          MetricDetailEntity(label: 'Out', value: outStock.compact()),
        ],
      ),
      MetricEntity(
        iconCodePoint: '0xe227',
        iconFontFamily: 'MaterialIcons',
        iconBgValue: 0xFFF3E8FF,
        iconColorValue: 0xFF7952DB,
        tableKey: DashboardTableKey.sales,
        label: 'Total Sales',
        value: 'MMK ${totalSales.compact()}',
        details: [
          MetricDetailEntity(label: 'In Cart', value: inCart.compact()),
          MetricDetailEntity(label: 'Sales', value: salesCount.compact()),
          MetricDetailEntity(label: 'Avg Sale', value: avgSale.compact()),
          MetricDetailEntity(
            label: 'Avg Products',
            value: avgProducts.toString(),
          ),
        ],
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

    final categoryQuantity = catQtyRes.map<CategoryQuantityEntity>((e) {
      final item = e as Map<String, dynamic>;
      return CategoryQuantityEntity(
        category: item.str('category_name', 'Unknown'),
        totalQuantity: item.integer('total_quantity'),
      );
    }).toList();

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

    final noBought = noBoughtRes.map<ProductItemEntity>((e) {
      final item = e as Map<String, dynamic>;
      final name = item['product_name'] as String? ?? 'Unknown';
      final image = item['product_image'] as String? ?? '';
      return ProductItemEntity(
        name: name,
        sold: 'Never sold',
        iconCodePoint: 0xe04c,
        iconFontFamily: 'MaterialIcons',
        image: image,
      );
    }).toList();

    return DashboardApiModel(
      metrics: metrics,
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
      categoryDistribution: categoryDistribution,
      categoryQuantity: categoryQuantity,
      mostBought: mostBought,
      leastBought: leastBought,
      noBought: noBought,
    );
  }
}
