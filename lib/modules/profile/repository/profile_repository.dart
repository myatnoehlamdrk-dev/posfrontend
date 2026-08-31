import 'package:posfrontend/modules/profile/model/profile_response.dart';

abstract class ProfileRepository {
  Future<ProfileResponse> getProfile();
  Future<ProfileResponse> updateProfile(Map<String, dynamic> data);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
