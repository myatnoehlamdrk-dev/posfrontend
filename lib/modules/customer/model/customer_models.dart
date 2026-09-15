class Customer {
  final int id;
  final int shopId;
  final String name;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.shopId,
    required this.name,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      shopId: json['shopId'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}

class CustomerAnalytics {
  final CustomerOverview overview;
  final List<CustomerSummaryItem> customerSummary;
  final List<TopCustomer> topCustomers;
  final List<SalesByLocation> salesByLocation;
  final NewVsReturning newVsReturning;
  final List<MonthlyTrend> monthlyTrends;
  final PurchaseBehavior purchaseBehavior;

  CustomerAnalytics({
    required this.overview,
    required this.customerSummary,
    required this.topCustomers,
    required this.salesByLocation,
    required this.newVsReturning,
    required this.monthlyTrends,
    required this.purchaseBehavior,
  });

  factory CustomerAnalytics.fromJson(Map<String, dynamic> json) {
    return CustomerAnalytics(
      overview: CustomerOverview.fromJson(json['overview'] ?? {}),
      customerSummary: (json['customerSummary'] as List? ?? [])
          .map((c) => CustomerSummaryItem.fromJson(c))
          .toList(),
      topCustomers: (json['topCustomers'] as List? ?? [])
          .map((c) => TopCustomer.fromJson(c))
          .toList(),
      salesByLocation: (json['salesByLocation'] as List? ?? [])
          .map((l) => SalesByLocation.fromJson(l))
          .toList(),
      newVsReturning: NewVsReturning.fromJson(json['newVsReturning'] ?? {}),
      monthlyTrends: (json['monthlyTrends'] as List? ?? [])
          .map((t) => MonthlyTrend.fromJson(t))
          .toList(),
      purchaseBehavior: PurchaseBehavior.fromJson(json['purchaseBehavior'] ?? {}),
    );
  }
}

class CustomerOverview {
  final int totalCustomers;
  final int newThisMonth;
  final int returningCustomers;
  final int walkInCount;

  CustomerOverview({
    required this.totalCustomers,
    required this.newThisMonth,
    required this.returningCustomers,
    required this.walkInCount,
  });

  factory CustomerOverview.fromJson(Map<String, dynamic> json) {
    return CustomerOverview(
      totalCustomers: json['totalCustomers'] ?? 0,
      newThisMonth: json['newThisMonth'] ?? 0,
      returningCustomers: json['returningCustomers'] ?? 0,
      walkInCount: json['walkInCount'] ?? 0,
    );
  }
}

class CustomerSummaryItem {
  final String name;
  final String phone;
  final String location;
  final int totalOrders;
  final int totalQuantity;
  final int totalSpending;
  final int avgOrderValue;
  final String? lastPurchaseDate;
  final List<TopProduct> topProducts;

  CustomerSummaryItem({
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

  factory CustomerSummaryItem.fromJson(Map<String, dynamic> json) {
    return CustomerSummaryItem(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      totalOrders: json['totalOrders'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
      totalSpending: json['totalSpending'] ?? 0,
      avgOrderValue: json['avgOrderValue'] ?? 0,
      lastPurchaseDate: json['lastPurchaseDate'],
      topProducts: (json['topProducts'] as List? ?? [])
          .map((p) => TopProduct.fromJson(p))
          .toList(),
    );
  }
}

class TopProduct {
  final String name;
  final int count;

  TopProduct({required this.name, required this.count});

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class TopCustomer {
  final String name;
  final String phone;
  final String location;
  final int totalOrders;
  final int totalSpending;

  TopCustomer({
    required this.name,
    required this.phone,
    required this.location,
    required this.totalOrders,
    required this.totalSpending,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      totalOrders: json['totalOrders'] ?? 0,
      totalSpending: json['totalSpending'] ?? 0,
    );
  }
}

class SalesByLocation {
  final String location;
  final int totalSales;
  final int percentage;

  SalesByLocation({
    required this.location,
    required this.totalSales,
    required this.percentage,
  });

  factory SalesByLocation.fromJson(Map<String, dynamic> json) {
    return SalesByLocation(
      location: json['location'] ?? '',
      totalSales: json['totalSales'] ?? 0,
      percentage: json['percentage'] ?? 0,
    );
  }
}

class NewVsReturning {
  final int newCount;
  final int returningCount;
  final int newPct;
  final int returningPct;

  NewVsReturning({
    required this.newCount,
    required this.returningCount,
    required this.newPct,
    required this.returningPct,
  });

  factory NewVsReturning.fromJson(Map<String, dynamic> json) {
    return NewVsReturning(
      newCount: json['newCount'] ?? 0,
      returningCount: json['returningCount'] ?? 0,
      newPct: json['newPct'] ?? 0,
      returningPct: json['returningPct'] ?? 0,
    );
  }
}

class MonthlyTrend {
  final String month;
  final int totalSpending;
  final int orderCount;
  final int uniqueCustomers;

  MonthlyTrend({
    required this.month,
    required this.totalSpending,
    required this.orderCount,
    required this.uniqueCustomers,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] ?? '',
      totalSpending: json['totalSpending'] ?? 0,
      orderCount: json['orderCount'] ?? 0,
      uniqueCustomers: json['uniqueCustomers'] ?? 0,
    );
  }
}

class PurchaseBehavior {
  final int avgSpendingPerCustomer;
  final String mostFrequentDay;
  final String mostFrequentHour;

  PurchaseBehavior({
    required this.avgSpendingPerCustomer,
    required this.mostFrequentDay,
    required this.mostFrequentHour,
  });

  factory PurchaseBehavior.fromJson(Map<String, dynamic> json) {
    return PurchaseBehavior(
      avgSpendingPerCustomer: json['avgSpendingPerCustomer'] ?? 0,
      mostFrequentDay: json['mostFrequentDay'] ?? '',
      mostFrequentHour: json['mostFrequentHour'] ?? '',
    );
  }
}

class CustomerSearchResult {
  final String name;
  final String? phone;

  CustomerSearchResult({required this.name, this.phone});

  factory CustomerSearchResult.fromJson(Map<String, dynamic> json) {
    return CustomerSearchResult(
      name: json['name'] ?? '',
      phone: json['phone'],
    );
  }
}
