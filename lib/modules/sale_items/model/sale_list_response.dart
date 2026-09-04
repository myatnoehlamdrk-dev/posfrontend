import 'package:posfrontend/modules/sale_items/model/sale_item_models.dart';

class PaginatedSalesResponse {
  final List<SaleOrder> data;
  final int lastPage;
  final int currentPage;
  final int total;

  const PaginatedSalesResponse({
    required this.data,
    required this.lastPage,
    required this.currentPage,
    required this.total,
  });

  factory PaginatedSalesResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<dynamic> itemsList;
    if (rawData is List) {
      itemsList = rawData;
    } else if (rawData is String) {
      itemsList = (json['data'] as List<dynamic>?) ?? [];
    } else {
      itemsList = [];
    }

    final items = itemsList
        .whereType<Map<String, dynamic>>()
        .map((e) => SaleOrder.fromJson(e))
        .toList();

    final meta = json['meta'];
    int lastPage = 1;
    int currentPage = 1;
    int total = 0;
    if (meta is Map<String, dynamic>) {
      lastPage = meta['last_page'] ?? 1;
      currentPage = meta['current_page'] ?? 1;
      total = meta['total'] ?? 0;
    }

    return PaginatedSalesResponse(
      data: items,
      lastPage: lastPage is int ? lastPage : 1,
      currentPage: currentPage is int ? currentPage : 1,
      total: total is int ? total : 0,
    );
  }
}

class PaginatedOrdersResponse {
  final List<SaleOrder> data;
  final int lastPage;
  final int currentPage;
  final int total;

  const PaginatedOrdersResponse({
    required this.data,
    required this.lastPage,
    required this.currentPage,
    required this.total,
  });

  factory PaginatedOrdersResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<dynamic> itemsList;
    if (rawData is List) {
      itemsList = rawData;
    } else if (rawData is String) {
      itemsList = (json['data'] as List<dynamic>?) ?? [];
    } else {
      itemsList = [];
    }

    final items = itemsList
        .whereType<Map<String, dynamic>>()
        .map((e) => SaleOrder.fromOrderJson(e))
        .toList();

    final meta = json['meta'];
    int lastPage = 1;
    int currentPage = 1;
    int total = 0;
    if (meta is Map<String, dynamic>) {
      lastPage = meta['last_page'] ?? 1;
      currentPage = meta['current_page'] ?? 1;
      total = meta['total'] ?? 0;
    }

    return PaginatedOrdersResponse(
      data: items,
      lastPage: lastPage is int ? lastPage : 1,
      currentPage: currentPage is int ? currentPage : 1,
      total: total is int ? total : 0,
    );
  }
}

class SaleDetailResponse {
  final SaleOrder data;

  const SaleDetailResponse({required this.data});

  factory SaleDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      return SaleDetailResponse(data: SaleOrder.fromJson(rawData));
    }
    return SaleDetailResponse(data: SaleOrder.fromJson(json));
  }
}
