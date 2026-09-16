import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/auth/domain/entities/user.dart';
import 'package:posfrontend/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase extends UseCase<UserEntity, RegisterParams> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<UserEntity> call(RegisterParams params) {
    return _repository.register(
      fullName: params.fullName,
      email: params.email,
      password: params.password,
      phone: params.phone,
      social: params.social,
      role: params.role,
      address: params.address,
      nrc: params.nrc,
      billingWay: params.billingWay,
      dob: params.dob,
      gender: params.gender,
      shopId: params.shopId,
    );
  }
}

class RegisterParams {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  final String? social;
  final String? role;
  final String? address;
  final String? nrc;
  final String? billingWay;
  final String? dob;
  final String? gender;
  final String? shopId;

  const RegisterParams({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
    this.social,
    this.role,
    this.address,
    this.nrc,
    this.billingWay,
    this.dob,
    this.gender,
    this.shopId,
  });
}
