import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_interceptor.dart';
import 'package:posfrontend/core/network/offline_cache_interceptor.dart';
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
  ///
  /// The production origin is the default so that *every* build — including a
  /// bare `flutter build apk` run without any flags — ships pointing at the
  /// real server. An unset `BASE_URL` used to be baked into shipped APKs as
  /// the empty string, which in release mode (where main.dart's assert is
  /// stripped) meant every request quietly went to `http://localhost`. Passing
  /// `--dart-define-from-file=config/env.json` still overrides this, which is
  /// what `tool\run.bat` and `tool\build.bat` do to target a LAN dev server.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://mdrkposbackend.onrender.com',
  );

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
  static String get apiRoot => apiRootFor(baseUrl, apiVersion);

  /// [baseUrl] joined to the versioned API path.
  ///
  /// Split out of [apiRoot] so the rule that produces it can be pinned with
  /// values the compile-time constant cannot take: [baseUrl] is baked in at
  /// build time, so a test running without `--dart-define` sees only the empty
  /// string and could assert nothing about the shape of a real origin.
  static String apiRootFor(String baseUrl, String version) {
    // Every trailing slash, not just one: `http://host:8000//` is one stray
    // keystroke away in a hand-edited env file, and it is the same double
    // slash the single-trim rule existed to prevent.
    final trimmed = baseUrl.replaceFirst(RegExp(r'/+$'), '');

    // An unset origin used to be joined as-is, producing the *relative* path
    // `/api/v1`. Dio 5 rejects that synchronously on every non-web platform
    // (`Invalid argument (baseUrl): Must be a valid URL on platforms other
    // than Web`), which threw out of main() before runApp() and froze the
    // release build on the native window splash — no Flutter frame, no error
    // dialog, nothing on screen to explain it. localhost is a valid absolute
    // URL that no device answers, so an unbaked BASE_URL now degrades to
    // "every request fails" — the behaviour main.dart's comment already
    // promised — instead of an invisible startup crash.
    if (trimmed.isEmpty) return 'http://localhost/api/$version';

    return '$trimmed/api/$version';
  }

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  /// A fresh client with the same interceptor chain as [instance].
  ///
  /// Ordinary call sites should use [instance]: one shared client means one
  /// interceptor chain and consistent token refresh. [create] exists for
  /// tests and the rare case that genuinely needs an isolated client.
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
    // First in the chain, which in dio 5 is also first to see responses
    // and errors. First for requests: a cache hit resolves before the auth
    // token read and the logger run. First for errors: a cache fallback
    // resolves before RetryInterceptor can spend its backoff budget
    // re-sending a request that has already been answered locally.
    dio.interceptors.add(OfflineCacheInterceptor());
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    dio.interceptors.add(AuthInterceptor());
    // After auth, so a retried request still carries the token: the first
    // attempt can fail on a 401 that a fresh token would have cleared.
    dio.interceptors.add(RetryInterceptor(dio));
    return dio;
  }
}