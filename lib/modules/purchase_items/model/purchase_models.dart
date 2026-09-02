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
      name: json['name'] as String? ?? '',
      phone: json['contact'] as String? ?? '',
      address: json['address'] as String? ?? '',
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
  });

  int get totalAmount => quantity * unitPrice;

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      orderId: json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: _parseInt(json['quantity']),
      unitPrice: _parseInt(json['unitPrice']),
      date: json['date'] as String? ?? '',
      status: json['status'] == 'completed'
          ? PurchaseStatus.completed
          : PurchaseStatus.pending,
      notes: json['notes'] as String? ?? '',
    );
  }
}
