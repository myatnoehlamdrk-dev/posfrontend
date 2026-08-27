import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/package/model/product_models.dart';
import 'package:posfrontend/modules/product/model/product_detail_models.dart';

abstract class ProductDetailRepository {
  ProductDetail getDetail(Product product, Category category);
}

class ProductDetailRepositoryImpl implements ProductDetailRepository {
  @override
  ProductDetail getDetail(Product product, Category category) {
    final brand = _brand(product.name);
    final available = product.quantity * 9 + 4;
    final reserved = (available * 0.06).round();
    final stockStatus = product.quantity == 0
        ? 'No Stock'
        : (product.quantity < 4 ? 'Low Stock' : 'Optimal');

    final catCode = _alpha(category.id).substring(0, 3);
    final brandCode = _alpha(brand).substring(0, 3);

    return ProductDetail(
      id: 'PRD-${(product.name.hashCode.abs() % 900 + 100)}',
      name: product.name,
      categoryName: category.name,
      sku: '$catCode-$brandCode-XM5',
      isBundle: 'No',
      brand: brand,
      color: 'Black',
      size: 'Standard',
      packageId: 'PKG-2024-00058',
      inventoryId: 'INV-2024-00007',
      status: 'Active',
      price: 199.99,
      stockAvailable: available,
      stockReserved: reserved,
      reorderLevel: 20,
      minStock: 10,
      maxCapacity: 300,
      stockStatus: stockStatus,
      supplierId: 'SUP-4821',
      supplierName: '$brand Global',
      contractNumber: 'CTR-2024-09-001',
      supplierSince: 'Sep 01, 2022',
    );
  }

  String _brand(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bose')) {
      return 'Bose';
    }
    if (lower.contains('sony')) {
      return 'Sony';
    }
    if (lower.contains('apple') ||
        lower.contains('ipad') ||
        lower.contains('iphone')) {
      return 'Apple';
    }
    if (lower.contains('samsung')) {
      return 'Samsung';
    }
    if (lower.contains('logitech')) {
      return 'Logitech';
    }
    if (lower.contains('dell')) {
      return 'Dell';
    }
    return 'Generic';
  }

  String _alpha(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (cleaned.isEmpty) {
      return 'GEN';
    }
    return cleaned.toUpperCase();
  }
}
