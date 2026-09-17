import 'package:equatable/equatable.dart';

enum PurchaseStatus { completed, pending }

class SupplierEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String address;

  const SupplierEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory SupplierEntity.fromJson(Map<String, dynamic> json) {
    return SupplierEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['contact']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, phone, address];
}

class PurchaseOrderEntity extends Equatable {
  final String orderId;
  final String supplierId;
  final String supplierName;
  final String productName;
  final String date;
  final String notes;
  final String createdBy;
  final String updatedBy;
  final String createdAt;
  final String updatedAt;
  final int quantity;
  final int unitPrice;
  final PurchaseStatus status;

  int get totalAmount => quantity * unitPrice;

  const PurchaseOrderEntity({
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

  factory PurchaseOrderEntity.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderEntity(
      orderId: json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      quantity: json['quantity'] is int ? json['quantity'] as int : int.tryParse('${json['quantity']}') ?? 0,
      unitPrice: json['unitPrice'] is int ? json['unitPrice'] as int : int.tryParse('${json['unitPrice']}') ?? 0,
      date: json['date']?.toString() ?? '',
      status: json['status'] == 'completed' ? PurchaseStatus.completed : PurchaseStatus.pending,
      notes: json['notes']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      updatedBy: json['updatedBy']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [orderId, supplierId, productName, status];
}

typedef PurchaseOrder = PurchaseOrderEntity;
typedef Supplier = SupplierEntity;
