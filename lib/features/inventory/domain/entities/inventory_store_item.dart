/// A row of the new `inventory_stores` table.
class InventoryStoreItem {
  final String id;
  final String name;
  final String sku;
  final String brand;
  final String category;
  final int quantityOnHand;
  final int quantityAvailable;
  final double retailPrice;
  final double costPrice;
  final int reorderPoint;
  final int safetyStock;
  final bool active;
  final DateTime? updatedAt;

  const InventoryStoreItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.brand,
    required this.category,
    required this.quantityOnHand,
    required this.quantityAvailable,
    required this.retailPrice,
    required this.costPrice,
    required this.reorderPoint,
    required this.safetyStock,
    this.active = true,
    this.updatedAt,
  });

  static const int lowStockThreshold = 5;

  String get status {
    if (quantityOnHand <= 0) return 'Out of Stock';
    if (reorderPoint > 0 && quantityOnHand <= reorderPoint) return 'Low Stock';
    if (quantityOnHand <= lowStockThreshold) return 'Low Stock';
    return 'In Stock';
  }

  double get value => retailPrice * quantityOnHand;

  factory InventoryStoreItem.fromJson(Map<String, dynamic> json) {
    DateTime? updated;
    final raw = json['updatedAt'] ?? json['updated_at'];
    if (raw is String && raw.isNotEmpty) {
      try {
        updated = DateTime.parse(raw).toLocal();
      } catch (_) {}
    }
    return InventoryStoreItem(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      quantityOnHand: (json['quantityOnHand'] ?? json['quantity_on_hand'] as num?)?.toInt() ?? 0,
      quantityAvailable: (json['quantityAvailable'] ?? json['quantity_available'] as num?)?.toInt() ?? 0,
      retailPrice: ((json['retailPrice'] ?? json['retail_price']) as num?)?.toDouble() ?? 0.0,
      costPrice: ((json['costPrice'] ?? json['cost_price']) as num?)?.toDouble() ?? 0.0,
      reorderPoint: (json['reorderPoint'] ?? json['reorder_point'] as num?)?.toInt() ?? 0,
      safetyStock: (json['safetyStock'] ?? json['safety_stock'] as num?)?.toInt() ?? 0,
      active: (json['active'] as bool?) ?? true,
      updatedAt: updated,
    );
  }
}