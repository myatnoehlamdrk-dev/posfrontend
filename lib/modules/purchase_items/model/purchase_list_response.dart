import 'package:posfrontend/modules/purchase_items/model/purchase_models.dart';

class PaginatedPurchaseItemsResponse {
  final List<PurchaseOrder> data;
  final int lastPage;
  final int currentPage;
  final int total;

  const PaginatedPurchaseItemsResponse({
    required this.data,
    required this.lastPage,
    required this.currentPage,
    required this.total,
  });

  factory PaginatedPurchaseItemsResponse.fromJson(Map<String, dynamic> json) {
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
        .map((e) => PurchaseOrder.fromJson(e))
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

    return PaginatedPurchaseItemsResponse(
      data: items,
      lastPage: lastPage is int ? lastPage : 1,
      currentPage: currentPage is int ? currentPage : 1,
      total: total is int ? total : 0,
    );
  }
}

class PurchaseItemDetailResponse {
  final PurchaseOrder data;

  const PurchaseItemDetailResponse({required this.data});

  factory PurchaseItemDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      return PurchaseItemDetailResponse(data: PurchaseOrder.fromJson(rawData));
    }
    return PurchaseItemDetailResponse(data: PurchaseOrder.fromJson(json));
  }
}
