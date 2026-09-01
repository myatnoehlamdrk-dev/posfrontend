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

  const PurchaseOrder({
    required this.orderId,
    required this.supplierId,
    required this.supplierName,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.date,
    required this.status,
  });

  int get totalAmount => quantity * unitPrice;
}
