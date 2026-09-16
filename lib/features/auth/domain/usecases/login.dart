import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/auth/domain/entities/login_result.dart';
import 'package:posfrontend/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase extends UseCase<LoginResult, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<LoginResult> call(LoginParams params) {
    return _repository.login(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}
