import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_interceptor.dart';
export 'package:posfrontend/core/network/app_exceptions.dart';

class ApiClient {
  static const String baseUrl = String.fromEnvironment('BASE_URL');

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  static Dio create() => _create();

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
    dio.interceptors.add(AuthInterceptor());
    return dio;
  }
}
