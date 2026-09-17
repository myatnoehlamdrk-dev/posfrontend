import 'package:posfrontend/core/extensions/map_json_extensions.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';

class PurchaseOrderApiModel {
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

  const PurchaseOrderApiModel({
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

  factory PurchaseOrderApiModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderApiModel(
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

  PurchaseOrderEntity toEntity() {
    return PurchaseOrderEntity(
      orderId: orderId,
      supplierId: supplierId,
      supplierName: supplierName,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      date: date,
      status: status,
      notes: notes,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class SupplierApiModel {
  final String id;
  final String name;
  final String phone;
  final String address;

  const SupplierApiModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory SupplierApiModel.fromJson(Map<String, dynamic> json) {
    return SupplierApiModel(
      id: json['id']?.toString() ?? '',
      name: json.str('name'),
      phone: json.str('contact'),
      address: json.str('address'),
    );
  }

  SupplierEntity toEntity() {
    return SupplierEntity(
      id: id,
      name: name,
      phone: phone,
      address: address,
    );
  }
}
