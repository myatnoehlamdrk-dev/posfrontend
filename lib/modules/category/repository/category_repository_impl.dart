import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  @override
  List<Category> getCategories() => const [
        Category(
          id: 'electronics',
          name: 'Electronics',
          packageCount: 12,
          description: 'Phones, laptops, accessories and smart gadgets.',
          createdDate: 'May 10, 2024',
          active: true,
          iconColor: Color(0xFF2563EB),
          icon: Icons.devices,
        ),
        Category(
          id: 'fashion',
          name: 'Fashion',
          packageCount: 18,
          description: 'Clothing, shoes and trendy wearable styles.',
          createdDate: 'May 12, 2024',
          active: true,
          iconColor: Color(0xFFDB2777),
          icon: Icons.checkroom,
        ),
        Category(
          id: 'grocery',
          name: 'Grocery',
          packageCount: 24,
          description: 'Daily food, beverages and household essentials.',
          createdDate: 'May 14, 2024',
          active: true,
          iconColor: Color(0xFF16A34A),
          icon: Icons.local_grocery_store,
        ),
        Category(
          id: 'home',
          name: 'Home & Living',
          packageCount: 15,
          description: 'Furniture, decor and kitchen utilities.',
          createdDate: 'May 16, 2024',
          active: true,
          iconColor: Color(0xFFEA580C),
          icon: Icons.chair,
        ),
        Category(
          id: 'beauty',
          name: 'Beauty & Health',
          packageCount: 10,
          description: 'Skincare, cosmetics and wellness products.',
          createdDate: 'May 18, 2024',
          active: false,
          iconColor: Color(0xFFEC4899),
          icon: Icons.spa,
        ),
        Category(
          id: 'sports',
          name: 'Sports',
          packageCount: 8,
          description: 'Gear and equipment for active lifestyles.',
          createdDate: 'May 20, 2024',
          active: true,
          iconColor: Color(0xFF0EA5E9),
          icon: Icons.sports_soccer,
        ),
        Category(
          id: 'books',
          name: 'Books & Stationery',
          packageCount: 7,
          description: 'Books, notebooks and writing supplies.',
          createdDate: 'May 22, 2024',
          active: true,
          iconColor: Color(0xFF7C3AED),
          icon: Icons.menu_book,
        ),
        Category(
          id: 'toys',
          name: 'Toys & Kids',
          packageCount: 6,
          description: 'Toys, games and children essentials.',
          createdDate: 'May 24, 2024',
          active: false,
          iconColor: Color(0xFFF59E0B),
          icon: Icons.toys,
        ),
      ];

  @override
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? amountOfPackage,
  }) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.post(
        '/api/categories',
        data: {
          'type': type,
          'name': name,
          'description': description,
          'amountOfPackage': amountOfPackage,
        },
      );
      final json = resp.data as Map<String, dynamic>;
      return Category(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? name,
        packageCount: json['amountOfPackage'] is int ? json['amountOfPackage'] as int : 0,
        description: json['description'] ?? '',
        createdDate: _today(),
        active: true,
        iconColor: const Color(0xFF6D28D9),
        icon: Icons.category,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  String _today() {
    final d = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
