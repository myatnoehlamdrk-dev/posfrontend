import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/forgot_password/repository/forgot_password_repository.dart';

class ForgotPasswordRepositoryImpl implements ForgotPasswordRepository {
  final Dio _dio;

  ForgotPasswordRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.create();

  @override
  Future<void> sendOtp(String email, {CancelToken? cancelToken}) async {
    try {
      await _dio.post('/api/auth/forgot-password/send-otp', data: {
        'email': email,
      }, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<String> verifyOtp(String email, String otp, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.post('/api/auth/forgot-password/verify-otp', data: {
        'email': email,
        'otp': otp,
      }, cancelToken: cancelToken);
      return response.data['reset_token'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.post('/api/auth/forgot-password/reset', data: {
        'email': email,
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': password,
      }, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
