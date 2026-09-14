import 'package:dio/dio.dart';

abstract class VerifyAccountRepository {
  Future<void> sendOtp(String email, {CancelToken? cancelToken});
  Future<void> verifyOtp(String email, String otp, {CancelToken? cancelToken});
}
