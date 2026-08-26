import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/register/model/register_request.dart';
import 'package:posfrontend/modules/register/model/user_model.dart';
import 'package:posfrontend/modules/register/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;

  AuthRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.create();

  @override
  Future<User> register(RegisterRequest request) async {
    try {
      // Auth controller: POST {BASE_URL}/api/auth/register
      final response = await _dio.post(
        '/api/auth/register',
        data: request.toJson(),
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
