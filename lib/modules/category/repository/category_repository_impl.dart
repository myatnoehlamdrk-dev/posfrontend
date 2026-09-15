import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/api_response_extensions.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({String? type, String? inventoryId, CancelToken? cancelToken}) async {
    try {
      final dio = ApiClient.create();
      final queryParameters = <String, dynamic>{};
      if (inventoryId != null) queryParameters['inventoryId'] = inventoryId;
      if (type != null) queryParameters['type'] = type;
      final resp = await dio.get(
        '/api/categories',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        cancelToken: cancelToken,
      );
      return parseTypedList(resp.data, _mapCategory);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Category _mapCategory(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] as String?;
    final rawImages = json['productImages'];
    final productImages = (rawImages is List)
        ? rawImages.whereType<String>().where((s) => s.isNotEmpty).toList()
        : <String>[];
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
      productImages: productImages,
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return d.toShortDate();
    } catch (_) {
      return iso;
    }
  }

  @override
  Future<Category> createCategory({
    required String type,
    required String name,
    String? description,
    int? packageLimit,
    CancelToken? cancelToken,
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
        cancelToken: cancelToken,
      );
      final json = resp.data as Map<String, dynamic>;
      return _mapCategory(json);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Category> updateCategory({
    required String id,
    required String name,
    String? description,
    int? packageLimit,
    CancelToken? cancelToken,
  }) async {
    try {
      final dio = ApiClient.create();
      final resp = await dio.put(
        '/api/categories/$id',
        data: {
          'name': name,
          'description': description,
          'packageLimit': packageLimit,
        },
        cancelToken: cancelToken,
      );
      final data = resp.data;
      final Map<String, dynamic> json =
          data is Map<String, dynamic> ? data : data['data'] as Map<String, dynamic>;
      return _mapCategory(json);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
