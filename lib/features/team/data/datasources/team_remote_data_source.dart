import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/team/data/models/shop_member_model.dart';

/// Shop membership endpoints. Every path is scoped server-side to the signed-in
/// user's shop; no shop id is sent from here.
class TeamRemoteDataSource {
  final Dio _dio;

  TeamRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  Future<TeamListModel> getMembers({
    String? query,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '/shop/members',
        queryParameters:
            (query == null || query.trim().isEmpty) ? null : {'q': query.trim()},
        cancelToken: cancelToken,
      );
      return TeamListModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ShopMemberModel> approve({
    required String userId,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/shop/members/$userId/approve',
        data: {'role': role},
      );
      return ShopMemberModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> reject(String userId) async {
    try {
      await _dio.post('/shop/members/$userId/reject');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ShopMemberModel> update({
    required String userId,
    String? role,
    bool? activeStatus,
  }) async {
    final data = <String, dynamic>{};
    if (role != null) data['role'] = role;
    if (activeStatus != null) data['active_status'] = activeStatus;

    try {
      final response = await _dio.patch(
        '/shop/members/$userId',
        data: data,
      );
      return ShopMemberModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> remove(String userId) async {
    try {
      await _dio.delete('/shop/members/$userId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
