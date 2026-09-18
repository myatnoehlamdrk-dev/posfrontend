import 'package:equatable/equatable.dart';

class SaleItemEntity extends Equatable {
  final String productId;
  final String productName;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final String? size;
  final String? color;
  final String? notes;
  final String category;

  const SaleItemEntity({
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

  SaleItemEntity copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
    String? size,
    String? color,
    String? notes,
    String? category,
  }) {
    return SaleItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [productId, productName, unitPrice, quantity, size, color];
}

enum PaymentMethod { cash, card, mobilePay, other }

String paymentMethodLabel(PaymentMethod m) {
  return switch (m) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.mobilePay => 'Mobile Pay',
    PaymentMethod.other => 'Other',
  };
}

enum SaleStatus { draft, completed }

enum OrderStatus { alreadySale, willBeSale }

class SaleOrderEntity extends Equatable {
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
  final String customerLocation;
  final String payMethod;
  final List<SaleItemDetailEntity> saleItems;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  const SaleOrderEntity({
    required this.orderId,
    this.voucherNo = '',
    this.productName = '',
    this.description = '',
    this.quantity = 0,
    this.date = '',
    this.status = OrderStatus.alreadySale,
    this.amount = 0,
    this.customerName = '',
    this.customerPhone = '',
    this.customerLocation = '',
    this.payMethod = 'Cash',
    this.saleItems = const [],
    this.createdBy = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  @override
  List<Object?> get props => [orderId, voucherNo, amount, status];
}

class SaleItemDetailEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int subtotal;
  final String size;
  final String color;

  const SaleItemDetailEntity({
    required this.id,
    this.productId = '',
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.size = '',
    this.color = '',
  });

  @override
  List<Object?> get props => [id, productName, quantity];
}

typedef SaleItem = SaleItemEntity;
