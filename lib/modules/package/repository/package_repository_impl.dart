import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/package/repository/package_repository.dart';

class PackageRepositoryImpl implements PackageRepository {
  @override
  List<Package> getPackages(String categoryId) {
    if (categoryId == 'electronics') return _electronics;
    return _generic(categoryId);
  }

  static const List<Package> _electronics = [
    Package(
      code: 'PKG-001',
      name: 'MacBook Pro 13',
      spec: '16GB RAM, 512GB SSD',
      quantity: 25,
      location: 'Aisle 4, Shelf 2',
      status: StockStatus.inStock,
    ),
    Package(
      code: 'PKG-002',
      name: 'Bose QC Headset',
      spec: 'Wireless, Noise Cancelling',
      quantity: 12,
      location: 'Aisle 1, B2',
      status: StockStatus.inStock,
    ),
    Package(
      code: 'PKG-003',
      name: 'iPhone 15 Pro',
      spec: '256GB, Titanium finish',
      quantity: 8,
      location: 'Aisle 2, Shelf 1',
      status: StockStatus.lowStock,
    ),
    Package(
      code: 'PKG-004',
      name: 'Samsung Monitor',
      spec: '27-inch 4K Display',
      quantity: 15,
      location: 'Aisle 4, Shelf 5',
      status: StockStatus.inStock,
    ),
    Package(
      code: 'PKG-005',
      name: 'Sony Speaker',
      spec: 'Bluetooth, 30W',
      quantity: 5,
      location: 'Aisle 3, Cabinet A1',
      status: StockStatus.lowStock,
    ),
    Package(
      code: 'PKG-006',
      name: 'iPad Air',
      spec: '64GB, WiFi',
      quantity: 0,
      location: 'Aisle 2, Shelf 3',
      status: StockStatus.outOfStock,
    ),
    Package(
      code: 'PKG-007',
      name: 'Logitech Keyboard',
      spec: 'Mechanical, RGB',
      quantity: 30,
      location: 'Aisle 5, Shelf 1',
      status: StockStatus.inStock,
    ),
    Package(
      code: 'PKG-008',
      name: 'Dell Laptop',
      spec: '8GB RAM, 256GB SSD',
      quantity: 10,
      location: 'Aisle 4, Shelf 3',
      status: StockStatus.inStock,
    ),
    Package(
      code: 'PKG-009',
      name: 'AirPods Pro',
      spec: 'Active Noise Cancellation',
      quantity: 18,
      location: 'Aisle 1, B1',
      status: StockStatus.inStock,
    ),
    Package(
      code: 'PKG-010',
      name: 'Gaming Mouse',
      spec: '16000 DPI, Wireless',
      quantity: 6,
      location: 'Aisle 5, Shelf 4',
      status: StockStatus.lowStock,
    ),
    Package(
      code: 'PKG-011',
      name: 'Webcam HD',
      spec: '1080p, USB',
      quantity: 22,
      location: 'Aisle 3, Shelf 2',
      status: StockStatus.inStock,
    ),
    Package(
      code: 'PKG-012',
      name: 'Smartphone X',
      spec: '128GB, Dual SIM',
      quantity: 3,
      location: 'Aisle 2, Shelf 6',
      status: StockStatus.lowStock,
    ),
  ];

  List<Package> _generic(String id) {
    final title = id[0].toUpperCase() + id.substring(1);
    final locations = [
      'Aisle 1, Shelf 1',
      'Aisle 2, B2',
      'Cabinet A1',
      'Aisle 3, Shelf 4',
      'B2, Rack 2',
      'Aisle 5, Shelf 3',
    ];
    final statuses = [
      StockStatus.inStock,
      StockStatus.lowStock,
      StockStatus.outOfStock,
      StockStatus.inStock,
      StockStatus.lowStock,
      StockStatus.inStock,
    ];
    final quantities = [25, 12, 0, 8, 5, 30];
    return List.generate(6, (i) {
      final n = i + 1;
      return Package(
        code: 'PKG-${n.toString().padLeft(3, '0')}',
        name: '$title Item $n',
        spec: 'Standard specification $n',
        quantity: quantities[i],
        location: locations[i],
        status: statuses[i],
      );
    });
  }
}
