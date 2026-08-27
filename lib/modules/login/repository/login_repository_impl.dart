import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/login/model/login_request.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/login/repository/login_repository.dart';

class LoginRepositoryImpl implements LoginRepository {
  final Dio _dio;

  LoginRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.create();

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      // Auth controller: POST {BASE_URL}/api/auth/login
      final response = await _dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
