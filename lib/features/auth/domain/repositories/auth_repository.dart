import 'package:posfrontend/features/auth/domain/entities/login_result.dart';
import 'package:posfrontend/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<LoginResult> login({
    required String email,
    required String password,
  });

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
  });

  Future<void> sendOtp({required String email});

  Future<void> verifyOtp({required String email, required String otp});

  Future<void> sendForgotPasswordOtp({required String email});

  Future<String> verifyForgotPasswordOtp({required String email, required String otp});

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
  });
}
