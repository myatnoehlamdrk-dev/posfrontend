import 'package:equatable/equatable.dart';

class ProductDetailEntity extends Equatable {
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
  final String supplierContact;
  final String contractNumber;
  final String supplierSince;
  final String supplierAddress;
  final String? imageUrl;
  final String? imageDeleteUrl;
  final List<dynamic> variants;
  final String createdBy;
  final String updatedBy;
  final String createdAt;
  final String updatedAt;

  const ProductDetailEntity({
    required this.id,
    required this.name,
    this.categoryName = '',
    this.sku = '',
    this.isBundle = 'No',
    this.brand = '',
    this.color = '',
    this.size = '',
    this.packageId = '',
    this.packageName = '',
    this.inventoryId = '',
    this.inventoryType = '',
    this.status = 'Active',
    this.price = 0,
    this.stockAvailable = 0,
    this.stockReserved = 0,
    this.reorderLevel = 10,
    this.minStock = 0,
    this.maxCapacity = 100,
    this.stockStatus = '',
    this.supplierId = '',
    this.supplierName = '',
    this.supplierContact = '',
    this.contractNumber = '',
    this.supplierSince = '',
    this.supplierAddress = '',
    this.imageUrl,
    this.imageDeleteUrl,
    this.variants = const [],
    this.createdBy = '',
    this.updatedBy = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  @override
  List<Object?> get props => [id, name, sku, price, stockAvailable];
}
