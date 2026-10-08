import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_interceptor.dart';
import 'package:posfrontend/core/network/retry_interceptor.dart';
export 'package:posfrontend/core/network/app_exceptions.dart';

class ApiClient {
  /// The server origin, with no path component.
  ///
  /// Deliberately kept free of the API prefix. [media_url.dart] resolves
  /// backend-local asset paths such as `/uploads/...` against this value, and
  /// those are served from the origin rather than from under `/api`. Prefixing
  /// here would silently rewrite every uploaded image URL to a 404. Use
  /// [apiRoot] when you need the versioned API base.
  static const String baseUrl = String.fromEnvironment('BASE_URL');

  /// The API version to talk to, as a bare segment: `v1`.
  ///
  /// Compile-time overridable so a v2 client can be built against a v2 server
  /// for testing without touching any call site. When a version's response
  /// shape changes incompatibly, add the new routes alongside the old ones
  /// server-side, bump this default, and only then retire the old version.
  static const String apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'v1',
  );

  /// The versioned API base every request is issued against.
  ///
  /// Request paths are written without the `/api/v1` prefix because Dio resolves
  /// a leading-slash path against this base's path rather than replacing it.
  /// `pinned by test/api_client_url_test.dart`, because the alternative -- the
  /// prefix repeated in ~110 call sites -- is a guarantee of drift, not of
  /// consistency.
  ///
  /// The trailing slash on [baseUrl] is trimmed because a `BASE_URL` ending in
  /// one is an easy env slip, and `http://host//api/v1` produces a double slash
  /// that some proxies answer with a redirect rather than the API.
  static String get apiRoot =>
      '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}/api/$apiVersion';

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  static Dio create() => _create();

  /// A client with no interceptors, for the one request whose 401 the caller
  /// must handle itself.
  ///
  /// [AuthInterceptor] reacts to a 401 by calling `redirectToLogin()`, which
  /// clears the token *and* pushes [LoginScreen]. That is right for ordinary
  /// calls mid-session, and wrong for the launch-time `GET /auth/me` probe:
  /// SplashScreen has not decided yet whether to go to the dashboard or to
  /// sign-in, and a redirect firing underneath it would race its own
  /// navigation and skip the get-started screen.
  ///
  /// The caller reads the status code and picks the route. It has to set the
  /// `Authorization` header itself, since there is no `AuthInterceptor` here
  /// to inject it.
  ///
  /// Timeouts are short and there is no [RetryInterceptor]: the probe sits
  /// behind a 2-second splash hold, and a retry loop would push a slow
  /// launch well past it. A failure is answered from the local session cache
  /// instead of by waiting longer.
  static Dio bare() {
    return Dio(
      BaseOptions(
        baseUrl: apiRoot,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: apiRoot,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    dio.interceptors.add(AuthInterceptor());
    // After auth, so a retried request still carries the token: the first
    // attempt can fail on a 401 that a fresh token would have cleared.
    dio.interceptors.add(RetryInterceptor(dio));
    return dio;
  }
}