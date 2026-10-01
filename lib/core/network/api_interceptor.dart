import 'package:dio/dio.dart';
import 'package:posfrontend/core/auth/auth_redirect.dart';
import 'package:posfrontend/core/auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // Any success means the session works again, so a later 401 is a real one
    // and the redirect guard must not swallow it.
    resetLoginRedirect();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // `redirectToLogin` clears the token itself, and guards against a burst
      // of parallel 401s each queueing a navigation. 403 is deliberately not
      // handled here: a permission problem means the session is valid, so
      // logging the tiller out over it would lose their cart.
      await redirectToLogin();
    }
    handler.next(err);
  }
}