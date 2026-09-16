import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/auth/domain/repositories/auth_repository.dart';

class SendForgotPasswordOtpUseCase extends UseCase<void, SendOtpParams> {
  final AuthRepository _repository;

  SendForgotPasswordOtpUseCase(this._repository);

  @override
  Future<void> call(SendOtpParams params) {
    return _repository.sendForgotPasswordOtp(email: params.email);
  }
}

class VerifyForgotPasswordOtpUseCase extends UseCase<String, VerifyOtpParams> {
  final AuthRepository _repository;

  VerifyForgotPasswordOtpUseCase(this._repository);

  @override
  Future<String> call(VerifyOtpParams params) {
    return _repository.verifyForgotPasswordOtp(email: params.email, otp: params.otp);
  }
}

class ResetPasswordUseCase extends UseCase<void, ResetPasswordParams> {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  @override
  Future<void> call(ResetPasswordParams params) {
    return _repository.resetPassword(
      email: params.email,
      resetToken: params.resetToken,
      password: params.password,
    );
  }
}

class SendOtpParams {
  final String email;
  const SendOtpParams({required this.email});
}

class VerifyOtpParams {
  final String email;
  final String otp;
  const VerifyOtpParams({required this.email, required this.otp});
}

class ResetPasswordParams {
  final String email;
  final String resetToken;
  final String password;
  const ResetPasswordParams({
    required this.email,
    required this.resetToken,
    required this.password,
  });
}
