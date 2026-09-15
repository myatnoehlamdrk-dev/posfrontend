import 'package:posfrontend/core/extensions/map_json_extensions.dart';

enum PurchaseStatus { completed, pending }

class Supplier {
  final String id;
  final String name;
  final String phone;
  final String address;

  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString() ?? '',
      name: json.str('name'),
      phone: json.str('contact'),
      address: json.str('address'),
    );
  }
}

class PurchaseOrder {
  final String orderId;
  final String supplierId;
  final String supplierName;
  final String productName;
  final int quantity;
  final int unitPrice;
  final String date;
  final PurchaseStatus status;
  final String notes;
  final String createdBy;
  final String updatedBy;
  final String createdAt;
  final String updatedAt;

  const PurchaseOrder({
    required this.orderId,
    required this.supplierId,
    required this.supplierName,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.date,
    required this.status,
    this.notes = '',
    this.createdBy = '',
    this.updatedBy = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  int get totalAmount => quantity * unitPrice;

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      orderId: json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json.str('supplierName'),
      productName: json.str('productName'),
      quantity: json.integer('quantity'),
      unitPrice: json.integer('unitPrice'),
      date: json.str('date'),
      status: json['status'] == 'completed'
          ? PurchaseStatus.completed
          : PurchaseStatus.pending,
      notes: json.str('notes'),
      createdBy: json.str('createdBy'),
      updatedBy: json.str('updatedBy'),
      createdAt: json.str('createdAt'),
      updatedAt: json.str('updatedAt'),
    );
  }
}
