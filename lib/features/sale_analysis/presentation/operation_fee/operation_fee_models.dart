import 'package:flutter/material.dart';

/// How a fee turns its rate into a monthly amount.
enum FeeCalculation { fixedPerMonth, percentageOfRevenue, perOrder, oneTime }

extension FeeCalculationX on FeeCalculation {
  String get label => switch (this) {
    FeeCalculation.fixedPerMonth => 'Fixed / month',
    FeeCalculation.percentageOfRevenue => '% of revenue',
    FeeCalculation.perOrder => 'Per order',
    FeeCalculation.oneTime => 'One-time',
  };

  bool get isPercentage => this == FeeCalculation.percentageOfRevenue;
}

enum FeeCategory { premises, transaction, fulfilment, people, other }

extension FeeCategoryX on FeeCategory {
  String get label => switch (this) {
    FeeCategory.premises => 'Premises',
    FeeCategory.transaction => 'Transaction',
    FeeCategory.fulfilment => 'Fulfilment',
    FeeCategory.people => 'People',
    FeeCategory.other => 'Other',
  };
}

/// Which icon a fee shows in the rules table.
enum FeeIcon { premises, transaction, fulfilment, people, other }

/// Which tint the fee's icon chip uses.
enum FeeTint { blue, violet, orange, green, gray }

/// How operation fees are shared across the catalogue.
enum AllocationMethod { revenue, unitsSold, grossProfit }

extension AllocationMethodX on AllocationMethod {
  String get label => switch (this) {
    AllocationMethod.revenue => 'Revenue',
    AllocationMethod.unitsSold => 'Units sold',
    AllocationMethod.grossProfit => 'Gross profit',
  };

  String get description => switch (this) {
    AllocationMethod.revenue => 'Products with more sales absorb more cost',
    AllocationMethod.unitsSold => 'Split costs across every item sold',
    AllocationMethod.grossProfit => 'Allocate based on product contribution',
  };
}

@immutable
class OperationFee {
  final String id;
  final String name;
  final FeeCategory category;
  final FeeCalculation calculation;
  final double rate;
  final bool isActive;
  final FeeIcon icon;
  final FeeTint tint;
  final DateTime? createdAt;

  const OperationFee({
    required this.id,
    required this.name,
    required this.category,
    required this.calculation,
    required this.rate,
    required this.isActive,
    required this.icon,
    required this.tint,
    this.createdAt,
  });

  OperationFee copyWith({
    String? name,
    FeeCategory? category,
    FeeCalculation? calculation,
    double? rate,
    bool? isActive,
    FeeIcon? icon,
    FeeTint? tint,
    DateTime? createdAt,
  }) {
    return OperationFee(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      calculation: calculation ?? this.calculation,
      rate: rate ?? this.rate,
      isActive: isActive ?? this.isActive,
      icon: icon ?? this.icon,
      tint: tint ?? this.tint,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Inactive rules cost nothing.
  double monthlyCost({
    required double revenue,
    required int orders,
    int? month,
    int? year,
  }) {
    if (!isActive) return 0;
    return switch (calculation) {
      FeeCalculation.fixedPerMonth => rate,
      FeeCalculation.percentageOfRevenue => revenue * rate / 100,
      FeeCalculation.perOrder => orders * rate,
      FeeCalculation.oneTime =>
        (month != null &&
                month == createdAt?.month &&
                (year ?? DateTime.now().year) == createdAt?.year)
            ? rate
            : 0,
    };
  }
}

/// Real per-product effect of the month's operation fees.
///
/// [revenue], [grossProfit] and [allocatedFee] are whole-month figures, which
/// is what the Revenue and Gross profit previews show. The remaining money
/// fields are per unit for the Units sold preview.
@immutable
class OperationFeeProductImpact {
  final String? productId;
  final String name;
  final String sku;
  final bool hasSales;
  final int units;
  final double revenue;
  final double grossProfit;
  final double allocatedFee;

  /// The month's total operation fee. It is the same for every allocation
  /// method; only this product's share of it changes.
  final double monthlyFee;
  final double unitSellingPrice;
  final double unitCost;
  final double unitAllocatedFee;
  final double trueUnitCost;
  final double trueMargin;

  const OperationFeeProductImpact({
    this.productId,
    required this.name,
    required this.sku,
    this.hasSales = true,
    required this.units,
    required this.revenue,
    this.grossProfit = 0,
    this.allocatedFee = 0,
    this.monthlyFee = 0,
    required this.unitSellingPrice,
    required this.unitCost,
    required this.unitAllocatedFee,
    required this.trueUnitCost,
    required this.trueMargin,
  });

  factory OperationFeeProductImpact.fromJson(Map<String, dynamic> json) {
    return OperationFeeProductImpact(
      productId: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      hasSales: json['hasSales'] as bool? ?? true,
      units: (json['units'] as num?)?.toInt() ?? 0,
      revenue: _toDouble(json['revenue']),
      grossProfit: _toDouble(json['grossProfit']),
      allocatedFee: _toDouble(json['allocatedFee']),
      monthlyFee: _toDouble(json['monthlyFee']),
      unitSellingPrice: _toDouble(json['unitSellingPrice']),
      unitCost: _toDouble(json['unitCost']),
      unitAllocatedFee: _toDouble(json['unitAllocatedFee']),
      trueUnitCost: _toDouble(json['trueUnitCost']),
      trueMargin: _toDouble(json['trueMargin']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// A product returned by the picker's search.
@immutable
class OperationFeeProductOption {
  final String id;
  final String name;
  final String sku;
  final String brand;

  const OperationFeeProductOption({
    required this.id,
    required this.name,
    this.sku = '',
    this.brand = '',
  });

  factory OperationFeeProductOption.fromJson(Map<String, dynamic> json) {
    return OperationFeeProductOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
    );
  }
}

/// Parses the stored allocation method without throwing on an unknown value.
AllocationMethod allocationMethodFromName(String? name) {
  return AllocationMethod.values.firstWhere(
    (method) => method.name == name,
    orElse: () => AllocationMethod.revenue,
  );
}
