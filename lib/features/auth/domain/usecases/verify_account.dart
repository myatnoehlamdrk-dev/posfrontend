import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/auth/domain/repositories/auth_repository.dart';

class SendOtpUseCase extends UseCase<void, SendOtpParams> {
  final AuthRepository _repository;

  SendOtpUseCase(this._repository);

  @override
  Future<void> call(SendOtpParams params) {
    return _repository.sendOtp(email: params.email);
  }
}

class SendOtpParams {
  final String email;

  const SendOtpParams({required this.email});
}

class VerifyOtpUseCase extends UseCase<void, VerifyOtpParams> {
  final AuthRepository _repository;

  VerifyOtpUseCase(this._repository);

  @override
  Future<void> call(VerifyOtpParams params) {
    return _repository.verifyOtp(email: params.email, otp: params.otp);
  }
}

class VerifyOtpParams {
  final String email;
  final String otp;

  const VerifyOtpParams({required this.email, required this.otp});
}
