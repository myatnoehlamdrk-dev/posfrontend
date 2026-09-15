import 'package:posfrontend/core/extensions/map_json_extensions.dart';

enum OrderStatus { alreadySale, willBeSale }

class SaleItemDetail {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int subtotal;
  final String size;
  final String color;

  const SaleItemDetail({
    required this.id,
    this.productId = '',
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.size = '',
    this.color = '',
  });

  factory SaleItemDetail.fromJson(Map<String, dynamic> json) {
    return SaleItemDetail(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json.str('productName'),
      quantity: json.integer('quantity'),
      unitPrice: json.integer('unitPrice'),
      subtotal: json.integer('subtotal'),
      size: json.str('size'),
      color: json.str('color'),
    );
  }
}

class SaleOrder {
  final String orderId;
  final String voucherNo;
  final String productName;
  final String description;
  final int quantity;
  final String date;
  final OrderStatus status;
  final int amount;
  final String customerName;
  final String customerPhone;
  final String payMethod;
  final List<SaleItemDetail> saleItems;
  final String createdBy;
  final String updatedBy;
  final String createdAt;
  final String updatedAt;

  const SaleOrder({
    required this.orderId,
    this.voucherNo = '',
    required this.productName,
    this.description = '',
    required this.quantity,
    required this.date,
    required this.status,
    required this.amount,
    this.customerName = '',
    this.customerPhone = '',
    this.payMethod = 'Cash',
    this.saleItems = const [],
    this.createdBy = '',
    this.updatedBy = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  static int _parseQuantitySold(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      if (value.contains(',')) {
        return value.split(',').fold<int>(0, (sum, e) => sum + (int.tryParse(e.trim()) ?? 0));
      }
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  factory SaleOrder.fromJson(Map<String, dynamic> json) {
    final saleItemsList = <SaleItemDetail>[];
    final rawSaleItems = json['saleItems'];
    if (rawSaleItems is List) {
      for (final item in rawSaleItems) {
        if (item is Map<String, dynamic>) {
          saleItemsList.add(SaleItemDetail.fromJson(item));
        }
      }
    }

    final totalQty = _parseQuantitySold(json['quantitySold']);
    final productName = json['productName'] as String? ?? 'Sale';

    return SaleOrder(
      orderId: json['id']?.toString() ?? '',
      voucherNo: json.str('voucherNo'),
      productName: productName,
      description: saleItemsList.map((e) => e.productName).join(', '),
      quantity: totalQty,
      date: json.str('createdAt'),
      status: OrderStatus.alreadySale,
      amount: json.integer('totalPrice'),
      customerName: json.str('customerName'),
      customerPhone: json.str('customerPhone'),
      payMethod: json.str('payMethod', 'Cash'),
      saleItems: saleItemsList,
      createdBy: json.str('createdBy'),
      updatedBy: json.str('updatedBy'),
      createdAt: json.str('createdAt'),
      updatedAt: json.str('updatedAt'),
    );
  }

  factory SaleOrder.fromOrderJson(Map<String, dynamic> json) {
    final saleItemsList = <SaleItemDetail>[];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          saleItemsList.add(SaleItemDetail.fromJson(item));
        }
      }
    }

    final totalQty = _parseQuantitySold(json['quantitySold']);
    final productName = json['productName'] as String? ?? 'Draft Order';

    final rawStatus = json['status'] as String? ?? 'draft';
    final status = rawStatus == 'finished' || rawStatus == 'completed'
        ? OrderStatus.alreadySale
        : OrderStatus.willBeSale;

    return SaleOrder(
      orderId: json['id']?.toString() ?? '',
      voucherNo: json.str('voucherNo'),
      productName: productName,
      description: saleItemsList.map((e) => e.productName).join(', '),
      quantity: totalQty,
      date: json.str('createdAt'),
      status: status,
      amount: json.integer('grandTotal'),
      customerName: json.str('customerName'),
      customerPhone: json.str('customerPhone'),
      payMethod: json.str('payMethod', 'Cash'),
      saleItems: saleItemsList,
      createdBy: json.str('createdBy'),
      updatedBy: json.str('updatedBy'),
      createdAt: json.str('createdAt'),
      updatedAt: json.str('updatedAt'),
    );
  }
}
