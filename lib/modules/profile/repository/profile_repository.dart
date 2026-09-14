import 'package:dio/dio.dart';
import 'package:posfrontend/modules/profile/model/profile_response.dart';

abstract class ProfileRepository {
  Future<ProfileResponse> getProfile({CancelToken? cancelToken});
  Future<ProfileResponse> updateProfile(Map<String, dynamic> data, {CancelToken? cancelToken});
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    CancelToken? cancelToken,
  });
}
