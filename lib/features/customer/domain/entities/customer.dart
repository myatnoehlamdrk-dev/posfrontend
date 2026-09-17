import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final int id;
  final int shopId;
  final String name;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerEntity({
    required this.id,
    required this.shopId,
    required this.name,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id];
}

class CustomerAnalyticsEntity extends Equatable {
  final CustomerOverviewEntity overview;
  final List<CustomerSummaryItemEntity> customerSummary;
  final List<TopCustomerEntity> topCustomers;
  final List<SalesByLocationEntity> salesByLocation;
  final NewVsReturningEntity newVsReturning;
  final List<MonthlyTrendEntity> monthlyTrends;
  final PurchaseBehaviorEntity purchaseBehavior;

  const CustomerAnalyticsEntity({
    required this.overview,
    required this.customerSummary,
    required this.topCustomers,
    required this.salesByLocation,
    required this.newVsReturning,
    required this.monthlyTrends,
    required this.purchaseBehavior,
  });

  @override
  List<Object?> get props => [overview, customerSummary, topCustomers, salesByLocation, newVsReturning, monthlyTrends, purchaseBehavior];
}

class CustomerOverviewEntity extends Equatable {
  final int totalCustomers;
  final int newThisMonth;
  final int returningCustomers;
  final int walkInCount;

  const CustomerOverviewEntity({
    required this.totalCustomers,
    required this.newThisMonth,
    required this.returningCustomers,
    required this.walkInCount,
  });

  @override
  List<Object?> get props => [totalCustomers, newThisMonth, returningCustomers, walkInCount];
}

class CustomerSummaryItemEntity extends Equatable {
  final String name;
  final String phone;
  final String location;
  final int totalOrders;
  final int totalQuantity;
  final int totalSpending;
  final int avgOrderValue;
  final String? lastPurchaseDate;
  final List<TopProductEntity> topProducts;

  const CustomerSummaryItemEntity({
    required this.name,
    required this.phone,
    required this.location,
    required this.totalOrders,
    required this.totalQuantity,
    required this.totalSpending,
    required this.avgOrderValue,
    this.lastPurchaseDate,
    required this.topProducts,
  });

  @override
  List<Object?> get props => [name, phone, location];
}

class TopProductEntity extends Equatable {
  final String name;
  final int count;

  const TopProductEntity({required this.name, required this.count});

  @override
  List<Object?> get props => [name, count];
}

class TopCustomerEntity extends Equatable {
  final String name;
  final String phone;
  final String location;
  final int totalOrders;
  final int totalSpending;

  const TopCustomerEntity({
    required this.name,
    required this.phone,
    required this.location,
    required this.totalOrders,
    required this.totalSpending,
  });

  @override
  List<Object?> get props => [name, phone, location];
}

class SalesByLocationEntity extends Equatable {
  final String location;
  final int totalSales;
  final int percentage;

  const SalesByLocationEntity({
    required this.location,
    required this.totalSales,
    required this.percentage,
  });

  @override
  List<Object?> get props => [location, totalSales, percentage];
}

class NewVsReturningEntity extends Equatable {
  final int newCount;
  final int returningCount;
  final int newPct;
  final int returningPct;

  const NewVsReturningEntity({
    required this.newCount,
    required this.returningCount,
    required this.newPct,
    required this.returningPct,
  });

  @override
  List<Object?> get props => [newCount, returningCount, newPct, returningPct];
}

class MonthlyTrendEntity extends Equatable {
  final String month;
  final int totalSpending;
  final int orderCount;
  final int uniqueCustomers;

  const MonthlyTrendEntity({
    required this.month,
    required this.totalSpending,
    required this.orderCount,
    required this.uniqueCustomers,
  });

  @override
  List<Object?> get props => [month, totalSpending, orderCount, uniqueCustomers];
}

class PurchaseBehaviorEntity extends Equatable {
  final int avgSpendingPerCustomer;
  final String mostFrequentDay;
  final String mostFrequentHour;

  const PurchaseBehaviorEntity({
    required this.avgSpendingPerCustomer,
    required this.mostFrequentDay,
    required this.mostFrequentHour,
  });

  @override
  List<Object?> get props => [avgSpendingPerCustomer, mostFrequentDay, mostFrequentHour];
}

class CustomerSearchResultEntity extends Equatable {
  final String name;
  final String? phone;

  const CustomerSearchResultEntity({required this.name, this.phone});

  @override
  List<Object?> get props => [name, phone];
}
