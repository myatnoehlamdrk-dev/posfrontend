import 'package:posfrontend/features/profile/domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile();
  Future<ProfileEntity> updateProfile(Map<String, dynamic> data);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
