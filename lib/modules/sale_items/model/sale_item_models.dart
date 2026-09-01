enum OrderStatus { alreadySale, willBeSale }

class SaleOrder {
  final String orderId;
  final String productName;
  final String description;
  final int quantity;
  final String date;
  final OrderStatus status;
  final int amount;
  final String customerName;

  const SaleOrder({
    required this.orderId,
    required this.productName,
    required this.description,
    required this.quantity,
    required this.date,
    required this.status,
    required this.amount,
    required this.customerName,
  });
}
