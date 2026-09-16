import 'package:posfrontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:posfrontend/features/auth/data/models/login_request_model.dart';
import 'package:posfrontend/features/auth/data/models/register_request_model.dart';
import 'package:posfrontend/features/auth/domain/entities/login_result.dart';
import 'package:posfrontend/features/auth/domain/entities/user.dart';
import 'package:posfrontend/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({AuthRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource();

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequestModel(email: email, password: password),
    );
    return LoginResult(
      user: response.toEntity(),
      accessToken: response.accessToken,
    );
  }

  @override
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? social,
    String? role,
    String? address,
    String? nrc,
    String? billingWay,
    String? dob,
    String? gender,
    String? shopId,
  }) async {
    final response = await _remoteDataSource.register(
      RegisterRequestModel(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        social: social,
        role: role,
        address: address,
        nrc: nrc,
        billingWay: billingWay,
        dob: dob,
        gender: gender,
        shopId: shopId,
      ),
    );
    return response.toEntity();
  }

  @override
  Future<void> sendOtp({required String email}) {
    return _remoteDataSource.sendOtp(email);
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) {
    return _remoteDataSource.verifyOtp(email, otp);
  }

  @override
  Future<void> sendForgotPasswordOtp({required String email}) {
    return _remoteDataSource.sendForgotPasswordOtp(email);
  }

  @override
  Future<String> verifyForgotPasswordOtp({required String email, required String otp}) {
    return _remoteDataSource.verifyForgotPasswordOtp(email, otp);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
  }) {
    return _remoteDataSource.resetPassword(
      email: email,
      resetToken: resetToken,
      password: password,
    );
  }
}
