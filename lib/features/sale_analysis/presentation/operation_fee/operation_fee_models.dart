import 'package:flutter/material.dart';

/// How a fee turns its rate into a monthly amount.
enum FeeCalculation { fixedPerMonth, percentageOfRevenue, perOrder }

extension FeeCalculationX on FeeCalculation {
  String get label => switch (this) {
        FeeCalculation.fixedPerMonth => 'Fixed / month',
        FeeCalculation.percentageOfRevenue => '% of revenue',
        FeeCalculation.perOrder => 'Per order',
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

  const OperationFee({
    required this.id,
    required this.name,
    required this.category,
    required this.calculation,
    required this.rate,
    required this.isActive,
    required this.icon,
    required this.tint,
  });

  OperationFee copyWith({
    String? name,
    FeeCategory? category,
    FeeCalculation? calculation,
    double? rate,
    bool? isActive,
    FeeIcon? icon,
    FeeTint? tint,
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
    );
  }

  /// Inactive rules cost nothing.
  double monthlyCost({required double revenue, required int orders}) {
    if (!isActive) return 0;
    return switch (calculation) {
      FeeCalculation.fixedPerMonth => rate,
      FeeCalculation.percentageOfRevenue => revenue * rate / 100,
      FeeCalculation.perOrder => orders * rate,
    };
  }
}

/// Seed rules shown on first open.
const List<OperationFee> defaultOperationFees = [
  OperationFee(
    id: 'shop-rent',
    name: 'Shop rent',
    category: FeeCategory.premises,
    calculation: FeeCalculation.fixedPerMonth,
    rate: 2800,
    isActive: true,
    icon: FeeIcon.premises,
    tint: FeeTint.blue,
  ),
  OperationFee(
    id: 'payment-processing',
    name: 'Payment processing',
    category: FeeCategory.transaction,
    calculation: FeeCalculation.percentageOfRevenue,
    rate: 2.4,
    isActive: true,
    icon: FeeIcon.transaction,
    tint: FeeTint.violet,
  ),
  OperationFee(
    id: 'packing-materials',
    name: 'Packing materials',
    category: FeeCategory.fulfilment,
    calculation: FeeCalculation.perOrder,
    rate: 1.20,
    isActive: true,
    icon: FeeIcon.fulfilment,
    tint: FeeTint.orange,
  ),
  OperationFee(
    id: 'utilities-internet',
    name: 'Utilities & internet',
    category: FeeCategory.premises,
    calculation: FeeCalculation.fixedPerMonth,
    rate: 680,
    isActive: true,
    icon: FeeIcon.premises,
    tint: FeeTint.blue,
  ),
  OperationFee(
    id: 'part-time-staff',
    name: 'Part-time staff',
    category: FeeCategory.people,
    calculation: FeeCalculation.fixedPerMonth,
    rate: 3200,
    isActive: true,
    icon: FeeIcon.people,
    tint: FeeTint.green,
  ),
];
