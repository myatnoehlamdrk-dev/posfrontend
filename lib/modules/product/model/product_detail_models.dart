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
  final String packageName;
  final String inventoryId;
  final String inventoryType;
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
  final String? imageUrl;

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
    required this.packageName,
    required this.inventoryId,
    required this.inventoryType,
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
    this.imageUrl,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final variants = json['variants'];
    final variantList = variants is List ? variants : const [];
    final price = variantList.isNotEmpty
        ? (variantList.first['price'] ?? 0).toDouble()
        : 0.0;
    final stock = (json['stock'] as num?)?.toInt() ?? 0;
    final size = (json['size'] as String?)?.isNotEmpty == true
        ? json['size'] as String
        : (variantList.isNotEmpty ? (variantList.first['size'] ?? '') : '');
    final image = (json['image'] as String?)?.trim();

    final stockStatus = stock == 0
        ? 'No Stock'
        : (stock < 10 ? 'Low Stock' : 'Optimal');

    return ProductDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed',
      categoryName: (json['category'] as String?)?.trim() ?? '',
      sku: (json['sku'] as String?)?.trim() ?? '—',
      isBundle: (json['isSet'] as bool? ?? false) ? 'Yes' : 'No',
      brand: (json['brand'] as String?)?.trim() ?? '—',
      color: (json['color'] as String?)?.trim() ?? '—',
      size: size?.toString() ?? '—',
      packageId: (json['packageId'] as String?)?.trim() ?? '—',
      packageName: (json['packageName'] as String?)?.trim() ?? '—',
      inventoryId: '—',
      inventoryType: (json['inventoryType'] as String?)?.trim() ?? '—',
      status: 'Active',
      price: price,
      stockAvailable: stock,
      stockReserved: 0,
      reorderLevel: 10,
      minStock: 5,
      maxCapacity: stock > 0 ? stock : 100,
      stockStatus: stockStatus,
      supplierId: (json['supplierId'] as String?)?.trim() ?? '—',
      supplierName: (json['supplierName'] as String?)?.trim() ?? '—',
      contractNumber: '—',
      supplierSince: '—',
      imageUrl: image != null && image.isNotEmpty ? image : null,
    );
  }
}
