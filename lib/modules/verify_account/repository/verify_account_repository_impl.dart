import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/verify_account/repository/verify_account_repository.dart';

class VerifyAccountRepositoryImpl implements VerifyAccountRepository {
  final Dio _dio;

  VerifyAccountRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.create();

  @override
  Future<void> sendOtp(String email, {CancelToken? cancelToken}) async {
    try {
      await _dio.post('/api/auth/register/send-otp', data: {
        'email': email,
      }, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> verifyOtp(String email, String otp, {CancelToken? cancelToken}) async {
    try {
      await _dio.post('/api/auth/register/verify-otp', data: {
        'email': email,
        'otp': otp,
      }, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
