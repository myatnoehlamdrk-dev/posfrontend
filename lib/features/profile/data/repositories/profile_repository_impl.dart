import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/profile/domain/entities/profile.dart';
import 'package:posfrontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:posfrontend/features/profile/data/models/profile_api_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final dio = ApiClient.create();

  @override
  Future<ProfileEntity> getProfile() async {
    final response = await dio.get('/api/auth/profile');
    return ProfileApiModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProfileEntity> updateProfile(Map<String, dynamic> data) async {
    final response = await dio.patch('/api/auth/profile', data: data);
    return ProfileApiModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await dio.put('/api/auth/profile/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': confirmPassword,
    });
  }
}
