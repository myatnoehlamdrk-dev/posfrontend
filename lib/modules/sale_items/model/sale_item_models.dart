enum OrderStatus { alreadySale, willBeSale }

class SaleItemDetail {
  final String id;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int subtotal;
  final String size;
  final String color;

  const SaleItemDetail({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.size = '',
    this.color = '',
  });

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  factory SaleItemDetail.fromJson(Map<String, dynamic> json) {
    return SaleItemDetail(
      id: json['id']?.toString() ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: _parseInt(json['quantity']),
      unitPrice: _parseInt(json['unitPrice']),
      subtotal: _parseInt(json['subtotal']),
      size: json['size'] as String? ?? '',
      color: json['color'] as String? ?? '',
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
  });

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

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
      voucherNo: json['voucherNo'] as String? ?? '',
      productName: productName,
      description: saleItemsList.map((e) => e.productName).join(', '),
      quantity: totalQty,
      date: json['createdAt'] as String? ?? '',
      status: OrderStatus.alreadySale,
      amount: _parseInt(json['totalPrice']),
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      payMethod: json['payMethod'] as String? ?? 'Cash',
      saleItems: saleItemsList,
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

    return SaleOrder(
      orderId: json['id']?.toString() ?? '',
      voucherNo: json['voucherNo'] as String? ?? '',
      productName: productName,
      description: saleItemsList.map((e) => e.productName).join(', '),
      quantity: totalQty,
      date: json['createdAt'] as String? ?? '',
      status: OrderStatus.willBeSale,
      amount: _parseInt(json['totalPrice'] ?? json['grandTotal']),
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      payMethod: json['payMethod'] as String? ?? 'Cash',
      saleItems: saleItemsList,
    );
  }
}
