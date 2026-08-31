import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/profile/model/profile_response.dart';
import 'package:posfrontend/modules/profile/repository/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final Dio _dio;

  ProfileRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.create();

  @override
  Future<ProfileResponse> getProfile() async {
    try {
      final response = await _dio.get('/api/auth/profile');
      return ProfileResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<ProfileResponse> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/auth/profile', data: data);
      return ProfileResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put('/api/auth/profile/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
