import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({String? type, String? inventoryId}) async {
    try {
      final dio = ApiClient.create();
      final queryParameters = <String, dynamic>{};
      if (inventoryId != null) queryParameters['inventoryId'] = inventoryId;
      if (type != null) queryParameters['type'] = type;
      final resp = await dio.get(
        '/api/categories',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      final data = _asList(resp.data);
      return data
          .map((e) => _mapCategory(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Category _mapCategory(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] as String?;
    return Category(
      id: json['id']?.toString() ?? '',
      inventoryId: json['inventoryId']?.toString() ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      packageCount: json['amountOfPackage'] is int ? json['amountOfPackage'] as int : 0,
      packageLimit: json['packageLimit'] is int
          ? json['packageLimit'] as int
          : int.tryParse(json['packageLimit']?.toString() ?? '') ?? 0,
      description: json['description'] ?? '',
      createdDate: createdAt != null ? _formatDate(createdAt) : '',
      createdAt: createdAt != null ? DateTime.tryParse(createdAt) : null,
      active: true,
      iconColor: const Color(0xFF6D28D9),
      icon: Icons.category,
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      return inner is List ? inner : [];
    }
    return [];
  }

  @override
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
  }) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.post(
        '/api/categories',
        data: {
          'type': type,
          'name': name,
          'description': description,
          'packageLimit': packageLimit,
        },
      );
      final json = resp.data as Map<String, dynamic>;
      return _mapCategory(json);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
