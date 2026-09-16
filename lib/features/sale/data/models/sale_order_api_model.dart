import 'package:posfrontend/core/extensions/map_json_extensions.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';

class SaleOrderApiModel {
  final String orderId;
  final String voucherNo;
  final String productName;
  final int quantity;
  final int amount;
  final String customerName;
  final String customerPhone;
  final String payMethod;
  final List<SaleItemDetailApiModel> saleItems;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final String status;

  const SaleOrderApiModel({
    required this.orderId,
    this.voucherNo = '',
    this.productName = '',
    this.quantity = 0,
    this.amount = 0,
    this.customerName = '',
    this.customerPhone = '',
    this.payMethod = 'Cash',
    this.saleItems = const [],
    this.createdBy = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.status = '',
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

  factory SaleOrderApiModel.fromJson(Map<String, dynamic> json) {
    final saleItemsList = <SaleItemDetailApiModel>[];
    final rawSaleItems = json['saleItems'];
    if (rawSaleItems is List) {
      for (final item in rawSaleItems) {
        if (item is Map<String, dynamic>) {
          saleItemsList.add(SaleItemDetailApiModel.fromJson(item));
        }
      }
    }
    return SaleOrderApiModel(
      orderId: json['id']?.toString() ?? '',
      voucherNo: json.str('voucherNo'),
      productName: json['productName'] as String? ?? 'Sale',
      quantity: _parseQuantitySold(json['quantitySold']),
      amount: json.integer('totalPrice'),
      customerName: json.str('customerName'),
      customerPhone: json.str('customerPhone'),
      payMethod: json.str('payMethod', 'Cash'),
      saleItems: saleItemsList,
      createdBy: json.str('createdBy'),
      createdAt: json.str('createdAt'),
      updatedAt: json.str('updatedAt'),
      status: 'completed',
    );
  }

  factory SaleOrderApiModel.fromOrderJson(Map<String, dynamic> json) {
    final saleItemsList = <SaleItemDetailApiModel>[];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          saleItemsList.add(SaleItemDetailApiModel.fromJson(item));
        }
      }
    }
    final rawStatus = json['status'] as String? ?? 'draft';
    return SaleOrderApiModel(
      orderId: json['id']?.toString() ?? '',
      voucherNo: json.str('voucherNo'),
      productName: json['productName'] as String? ?? 'Draft Order',
      quantity: _parseQuantitySold(json['quantitySold']),
      amount: json.integer('grandTotal'),
      customerName: json.str('customerName'),
      customerPhone: json.str('customerPhone'),
      payMethod: json.str('payMethod', 'Cash'),
      saleItems: saleItemsList,
      createdBy: json.str('createdBy'),
      createdAt: json.str('createdAt'),
      updatedAt: json.str('updatedAt'),
      status: rawStatus,
    );
  }

  SaleOrderEntity toEntity() {
    final orderStatus = status == 'completed' || status == 'finished'
        ? OrderStatus.alreadySale
        : OrderStatus.willBeSale;
    final desc = saleItems.map((e) => e.productName).join(', ');
    return SaleOrderEntity(
      orderId: orderId,
      voucherNo: voucherNo,
      productName: productName,
      description: desc,
      quantity: quantity,
      date: createdAt,
      status: orderStatus,
      amount: amount,
      customerName: customerName,
      customerPhone: customerPhone,
      payMethod: payMethod,
      saleItems: saleItems.map((e) => e.toEntity()).toList(),
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class SaleItemDetailApiModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int subtotal;
  final String size;
  final String color;

  const SaleItemDetailApiModel({
    required this.id,
    this.productId = '',
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.size = '',
    this.color = '',
  });

  factory SaleItemDetailApiModel.fromJson(Map<String, dynamic> json) {
    return SaleItemDetailApiModel(
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

  SaleItemDetailEntity toEntity() {
    return SaleItemDetailEntity(
      id: id,
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      subtotal: subtotal,
      size: size,
      color: color,
    );
  }
}
