class ProductDetail {
  final String id;
  final String name;
  final String categoryName;
  final String sku;
  final String isBundle;
  final String brand;
  final String color;
  final String size;
  final String packageId;
  final String inventoryId;
  final String status;
  final double price;
  final int stockAvailable;
  final int stockReserved;
  final int reorderLevel;
  final int minStock;
  final int maxCapacity;
  final String stockStatus;
  final String supplierId;
  final String supplierName;
  final String contractNumber;
  final String supplierSince;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.sku,
    required this.isBundle,
    required this.brand,
    required this.color,
    required this.size,
    required this.packageId,
    required this.inventoryId,
    required this.status,
    required this.price,
    required this.stockAvailable,
    required this.stockReserved,
    required this.reorderLevel,
    required this.minStock,
    required this.maxCapacity,
    required this.stockStatus,
    required this.supplierId,
    required this.supplierName,
    required this.contractNumber,
    required this.supplierSince,
  });
}
