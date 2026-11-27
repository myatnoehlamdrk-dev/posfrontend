import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/auth/domain/repositories/auth_repository.dart';

/// Cancels a pending join request so the email can be registered again.
///
/// Credentials are passed rather than a token: a pending account was never
/// issued one. This is a plain `UseCase` like the other auth actions so the
/// pending screen can call it through the same DI path as login.
class WithdrawMembershipRequestUseCase
    extends UseCase<void, WithdrawMembershipRequestParams> {
  final AuthRepository _repository;

  WithdrawMembershipRequestUseCase(this._repository);

  @override
  Future<void> call(WithdrawMembershipRequestParams params) {
    return _repository.withdrawMembershipRequest(
      email: params.email,
      password: params.password,
    );
  }
}

class WithdrawMembershipRequestParams {
  final String email;
  final String password;

  const WithdrawMembershipRequestParams({
    required this.email,
    required this.password,
  });
}
