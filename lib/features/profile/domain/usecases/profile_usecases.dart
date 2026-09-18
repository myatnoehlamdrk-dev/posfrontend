import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/profile/domain/entities/profile.dart';
import 'package:posfrontend/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUseCase extends UseCase<ProfileEntity, NoParams> {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  @override
  Future<ProfileEntity> call(NoParams params) {
    return repository.getProfile();
  }
}

class UpdateProfileUseCase extends UseCase<ProfileEntity, Map<String, dynamic>> {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<ProfileEntity> call(Map<String, dynamic> data) {
    return repository.updateProfile(data);
  }
}

class ChangePasswordUseCase extends UseCase<void, ChangePasswordParams> {
  final ProfileRepository repository;

  ChangePasswordUseCase(this.repository);

  @override
  Future<void> call(ChangePasswordParams params) {
    return repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
      confirmPassword: params.confirmPassword,
    );
  }
}

class ChangePasswordParams {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordParams({required this.currentPassword, required this.newPassword, required this.confirmPassword});
}
