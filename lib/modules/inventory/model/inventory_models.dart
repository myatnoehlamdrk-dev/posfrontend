class InventoryOption {
  final String key;
  final String title;
  final String description;

  const InventoryOption(this.key, this.title, this.description);
}

class Inventory {
  final String id;
  final String shopId;
  final String type;
  final int amountCategory;

  const Inventory({
    required this.id,
    required this.shopId,
    required this.type,
    this.amountCategory = 0,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amountCategory'];
    return Inventory(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      type: json['type'] ?? '',
      amountCategory: rawAmount is int
          ? rawAmount
          : int.tryParse(rawAmount?.toString() ?? '') ?? 0,
    );
  }
}
