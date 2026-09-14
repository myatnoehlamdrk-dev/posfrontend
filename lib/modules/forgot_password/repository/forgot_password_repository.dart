import 'package:dio/dio.dart';

abstract class ForgotPasswordRepository {
  Future<void> sendOtp(String email, {CancelToken? cancelToken});
  Future<String> verifyOtp(String email, String otp, {CancelToken? cancelToken});
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    CancelToken? cancelToken,
  });
}
