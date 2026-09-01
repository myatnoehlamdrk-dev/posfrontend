class SaleItem {
  final String productId;
  final String productName;
  final String? imageUrl;
  final double unitPrice;
  int quantity;
  String? size;
  String? color;
  String? notes;
  final String category;

  SaleItem({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.unitPrice,
    this.quantity = 1,
    this.size,
    this.color,
    this.notes,
    this.category = '',
  });

  double get subtotal => unitPrice * quantity;
}

enum PaymentMethod { cash, card, mobilePay, other }

String paymentMethodLabel(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cash:
      return 'Cash';
    case PaymentMethod.card:
      return 'Card';
    case PaymentMethod.mobilePay:
      return 'Mobile Pay';
    case PaymentMethod.other:
      return 'Other';
  }
}

enum SaleStatus { draft, completed }

class SaleData {
  final String voucherNo;
  final String? customerId;
  final String customerName;
  final DateTime dateTime;
  final List<SaleItem> items;
  final double discount;
  final PaymentMethod paymentMethod;
  final String? orderId;
  final String? notes;
  final SaleStatus status;

  SaleData({
    required this.voucherNo,
    this.customerId,
    required this.customerName,
    required this.dateTime,
    required this.items,
    this.discount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.orderId,
    this.notes,
    this.status = SaleStatus.draft,
  });

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);
  double get discountAmount => subtotal * (discount / 100);
  double get totalPayable => subtotal - discountAmount;
}
