import 'package:posfrontend/features/customer/domain/entities/customer.dart';

class CustomerApiModel {
  static CustomerAnalyticsEntity analyticsFromJson(Map<String, dynamic> json) {
    return CustomerAnalyticsEntity(
      overview: CustomerOverviewEntity(
        totalCustomers: json['overview']?['totalCustomers'] ?? 0,
        newThisMonth: json['overview']?['newThisMonth'] ?? 0,
        returningCustomers: json['overview']?['returningCustomers'] ?? 0,
        walkInCount: json['overview']?['walkInCount'] ?? 0,
      ),
      customerSummary: (json['customerSummary'] as List? ?? []).map((c) => CustomerSummaryItemEntity(
        name: c['name'] ?? '',
        phone: c['phone'] ?? '',
        location: c['location'] ?? '',
        totalOrders: c['totalOrders'] ?? 0,
        totalQuantity: c['totalQuantity'] ?? 0,
        totalSpending: c['totalSpending'] ?? 0,
        avgOrderValue: c['avgOrderValue'] ?? 0,
        lastPurchaseDate: c['lastPurchaseDate'],
        topProducts: (c['topProducts'] as List? ?? []).map((p) => TopProductEntity(
          name: p['name'] ?? '',
          count: p['count'] ?? 0,
        )).toList(),
      )).toList(),
      topCustomers: (json['topCustomers'] as List? ?? []).map((c) => TopCustomerEntity(
        name: c['name'] ?? '',
        phone: c['phone'] ?? '',
        location: c['location'] ?? '',
        totalOrders: c['totalOrders'] ?? 0,
        totalSpending: c['totalSpending'] ?? 0,
      )).toList(),
      salesByLocation: (json['salesByLocation'] as List? ?? []).map((l) => SalesByLocationEntity(
        location: l['location'] ?? '',
        totalSales: l['totalSales'] ?? 0,
        percentage: l['percentage'] ?? 0,
      )).toList(),
      newVsReturning: NewVsReturningEntity(
        newCount: json['newVsReturning']?['newCount'] ?? 0,
        returningCount: json['newVsReturning']?['returningCount'] ?? 0,
        newPct: json['newVsReturning']?['newPct'] ?? 0,
        returningPct: json['newVsReturning']?['returningPct'] ?? 0,
      ),
      monthlyTrends: (json['monthlyTrends'] as List? ?? []).map((t) => MonthlyTrendEntity(
        month: t['month'] ?? '',
        totalSpending: t['totalSpending'] ?? 0,
        orderCount: t['orderCount'] ?? 0,
        uniqueCustomers: t['uniqueCustomers'] ?? 0,
      )).toList(),
      purchaseBehavior: PurchaseBehaviorEntity(
        avgSpendingPerCustomer: json['purchaseBehavior']?['avgSpendingPerCustomer'] ?? 0,
        mostFrequentDay: json['purchaseBehavior']?['mostFrequentDay'] ?? '',
        mostFrequentHour: json['purchaseBehavior']?['mostFrequentHour'] ?? '',
      ),
    );
  }

  static List<CustomerSearchResultEntity> searchResultsFromJson(List<dynamic> json) {
    return json.map((c) => CustomerSearchResultEntity(
      name: c['name'] ?? '',
      phone: c['phone'],
    )).toList();
  }
}
