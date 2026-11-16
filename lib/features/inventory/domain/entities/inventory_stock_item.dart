/// A single row of the Stock Overview inventory table.
///
/// Parsed straight from the `GET /products` payload so the screen does not
/// depend on the catalog's view model. Only the fields the table needs are
/// kept; everything else is ignored.
class InventoryStockItem {
  final String id;
  final String name;
  final String sku;
  final String category;
  final String supplierName;
  final int stock;
  final double price;
  final String? imageUrl;
  final DateTime? updatedAt;

  const InventoryStockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.supplierName,
    required this.stock,
    required this.price,
    this.imageUrl,
    this.updatedAt,
  });

  /// Low-stock threshold shared with the dashboard's `low_stock_count` so the
  /// table and the KPI card never disagree.
  static const int lowStockThreshold = 5;

  String get status {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= lowStockThreshold) return 'Low Stock';
    return 'In Stock';
  }

  double get value => price * stock;

  factory InventoryStockItem.fromJson(Map<String, dynamic> json) {
    final variants = json['variants'];
    final variantList = variants is List ? variants : const [];
    final price = variantList.isNotEmpty
        ? ((variantList.first['price'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    DateTime? updated;
    final rawUpdated = json['updatedAt'] ?? json['updated_at'];
    if (rawUpdated is String && rawUpdated.isNotEmpty) {
      try {
        updated = DateTime.parse(rawUpdated).toLocal();
      } catch (_) {
        updated = null;
      }
    }
    return InventoryStockItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: (json['sku'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      supplierName: (json['supplierName'] ?? json['supplier_name'] ?? '').toString(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      price: price,
      imageUrl: (json['image'] is String && (json['image'] as String).isNotEmpty)
          ? json['image'].toString()
          : null,
      updatedAt: updated,
    );
  }
}