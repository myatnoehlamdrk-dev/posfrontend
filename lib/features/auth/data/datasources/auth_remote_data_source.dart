import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/auth/data/models/login_request_model.dart';
import 'package:posfrontend/features/auth/data/models/login_response_model.dart';
import 'package:posfrontend/features/auth/data/models/register_request_model.dart';
import 'package:posfrontend/features/auth/data/models/user_api_model.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource([Dio? dio]) : _dio = dio ?? ApiClient.create();

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );
      return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserApiModel> register(RegisterRequestModel request) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: request.toJson(),
      );
      return UserApiModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      await _dio.post('/api/auth/register/send-otp', data: {
        'email': email,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    try {
      await _dio.post('/api/auth/register/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> sendForgotPasswordOtp(String email) async {
    try {
      await _dio.post('/api/auth/forgot-password/send-otp', data: {
        'email': email,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> verifyForgotPasswordOtp(String email, String otp) async {
    try {
      final response = await _dio.post('/api/auth/forgot-password/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      return response.data['reset_token'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
  }) async {
    try {
      await _dio.post('/api/auth/forgot-password/reset', data: {
        'email': email,
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': password,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
