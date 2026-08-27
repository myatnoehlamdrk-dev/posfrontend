import 'package:flutter/material.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/product/repository/catalog_product_repository.dart';

class CatalogProductRepositoryImpl implements CatalogProductRepository {
  @override
  List<CatalogProduct> getProducts() => const [
        CatalogProduct(
          id: 'PRD-201',
          name: 'Wireless Headphones Pro',
          brand: 'Sony',
          sku: 'AUD-SNY-WHPRO',
          price: 89,
          stock: 42,
          category: 'Audio',
          icon: Icons.headphones,
          color: Color(0xFF6D28D9),
        ),
        CatalogProduct(
          id: 'PRD-202',
          name: 'TWS Earbuds Set',
          brand: 'Bose',
          sku: 'AUD-BOS-TWS',
          price: 59,
          stock: 118,
          isSet: true,
          category: 'Audio',
          icon: Icons.earbuds,
          color: Color(0xFF7C3AED),
        ),
        CatalogProduct(
          id: 'PRD-203',
          name: 'USB-C Fast Charger',
          brand: 'Anker',
          sku: 'CHG-ANK-USBC',
          price: 29,
          stock: 256,
          category: 'Charging',
          icon: Icons.flash_on,
          color: Color(0xFFEA580C),
        ),
        CatalogProduct(
          id: 'PRD-204',
          name: 'Gaming Mouse X9',
          brand: 'Logitech',
          sku: 'PER-LOG-GM9',
          price: 49,
          stock: 73,
          category: 'Peripherals',
          icon: Icons.mouse,
          color: Color(0xFF0EA5E9),
        ),
        CatalogProduct(
          id: 'PRD-205',
          name: 'Bluetooth Speaker Mini',
          brand: 'JBL',
          sku: 'AUD-JBL-BSM',
          price: 39,
          stock: 88,
          category: 'Audio',
          icon: Icons.speaker,
          color: Color(0xFF16A34A),
        ),
      ];
}
