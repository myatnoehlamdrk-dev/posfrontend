class CartItemEntity {
  final String productId;
  final String productName;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final String category;
  final String? size;
  final String? color;

  const CartItemEntity({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.category = '',
    this.size,
    this.color,
  });

  double get subtotal => unitPrice * quantity;

  String get variantLabel {
    final parts = <String>[
      if (size != null && size!.isNotEmpty) size!,
      if (color != null && color!.isNotEmpty) color!,
    ];
    return parts.join(' · ');
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'imageUrl': imageUrl,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'category': category,
        'size': size,
        'color': color,
      };

  factory CartItemEntity.fromJson(Map<String, dynamic> json) {
    return CartItemEntity(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      size: json['size'] as String?,
      color: json['color'] as String?,
    );
  }
}