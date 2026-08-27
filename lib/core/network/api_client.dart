import 'package:dio/dio.dart';
import 'package:posfrontend/core/auth/token_storage.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException({this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';

  static ApiException fromDio(DioException e) {
    final data = e.response?.data;
    var message = e.message ?? 'Network error';
    if (data is Map<String, dynamic> && data['message'] != null) {
      message = data['message'].toString();
    } else if (data is Map<String, dynamic> && data['error'] != null) {
      message = data['error'].toString();
    }
    return ApiException(statusCode: e.response?.statusCode, message: message);
  }
}

class ApiClient {
  static const String baseUrl = String.fromEnvironment('BASE_URL');

  static Dio create() {
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
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    return dio;
  }
}
