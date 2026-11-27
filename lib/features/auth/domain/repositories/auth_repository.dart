import 'package:posfrontend/features/auth/domain/entities/login_result.dart';
import 'package:posfrontend/features/auth/domain/entities/user.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart';

abstract class AuthRepository {
  Future<LoginResult> login({
    required String email,
    required String password,
    String? deviceName,
  });

  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? social,
    String? address,
    String? nrc,
    String? billingWay,
    String? dob,
    String? gender,
    String? shopId,
    ShopEntity? shop,
  });

  /// Withdraw a pending join request. Unauthenticated on the server because a
  /// pending account has no token; the credentials are the proof.
  Future<void> withdrawMembershipRequest({
    required String email,
    required String password,
  });

  Future<void> sendOtp({required String email});

  Future<void> verifyOtp({required String email, required String otp});

  Future<void> sendForgotPasswordOtp({required String email});

  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  });

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
  });
}
