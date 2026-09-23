import 'package:equatable/equatable.dart';

class DashboardEntity extends Equatable {
  final List<MetricEntity> metrics;
  final List<CategoryDistributionEntity> categoryDistribution;
  final List<CategoryQuantityEntity> categoryQuantity;
  final List<ProductItemEntity> mostBought;
  final List<ProductItemEntity> leastBought;
  final List<ProductItemEntity> noBought;

  const DashboardEntity({
    required this.metrics,
    required this.categoryDistribution,
    required this.categoryQuantity,
    required this.mostBought,
    required this.leastBought,
    required this.noBought,
  });

  @override
  List<Object?> get props => [
        metrics,
        categoryDistribution,
        categoryQuantity,
        mostBought,
        leastBought,
        noBought,
      ];
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

  const MonthlySalesEntity({
    required this.month,
    required this.total,
  });

  @override
  List<Object?> get props => [month, total];
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
