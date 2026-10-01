import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';

/// Retries transient failures for safe methods only.
///
/// ## Why the method allowlist is so narrow
///
/// A retry re-sends a request that may already have been processed. That is
/// harmless for GET and HEAD, which are meant to be idempotent reads. It is
/// not harmless for a POS: retrying `POST /api/v1/sales` after a response
/// times out can sell the same basket to a customer twice, and retrying
/// `DELETE` after a timeout can delete a row the tiller has since recreated.
/// So anything that mutates is retried only where the server has declared it
/// safe to repeat, via the `X-Safe-Retry` request header, and never on a
/// guess made here.
///
/// ## What counts as transient
///
/// Connectivity and server-side faults only. A 4xx other than 429 means the
/// request itself was wrong or the caller is not allowed to make it; sending
/// the identical request again would fail identically, and retrying a 401
/// three times just delays the login redirect.
///
/// ## Backoff
///
/// 429 is honoured from the standard `Retry-After` header, in both the
/// delta-seconds and the HTTP-date forms. Everything else backs off
/// exponentially from [_baseDelay]. The delay is capped at [_maxDelay] so a
/// hostile or misconfigured server cannot park the app in a sleep long enough
/// to look like a hang.
class RetryInterceptor extends Interceptor {
  /// Methods retried without an explicit opt-in from the caller.
  static const Set<String> _safeMethods = {'GET', 'HEAD', 'OPTIONS'};

  /// Statuses worth trying again. 429 is included because the limit is a
  /// window, not a permanent refusal, and the header tells us when it lifts.
  static const Set<int> _retryableStatuses = {408, 429, 500, 502, 503, 504};

  static const int maxAttempts = 3;
  static const Duration _baseDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 30);

  /// Takes the client it belongs to, because Dio gives an interceptor no way to
  /// reach its own.
  ///
  /// It has to be the configured client: building a fresh `Dio()` to send the
  /// retry would silently discard everything set up on the real one -- a mock
  /// adapter in tests, a corporate proxy or pinned certificate in the field --
  /// and the retry would go out over a connection nothing else is using.
  /// Re-dispatching through the original also re-runs the auth interceptor, so
  /// a retry picks up a token refreshed after the attempt it replaces.
  const RetryInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    // Dio carries the attempt count in extra, which survives a retry of the
    // same RequestOptions. Counting off extra rather than off local state keeps
    // two interceptors from each seeing a fresh budget.
    final attempt = (options.extra['retry_attempt'] as int? ?? 0) + 1;
    if (attempt >= maxAttempts) {
      handler.next(err);
      return;
    }

    options.extra['retry_attempt'] = attempt;

    final delay = err.response?.statusCode == 429
        ? _retryAfter(err) ?? _exponential(attempt)
        : _exponential(attempt);

    await Future<void>.delayed(delay);

    // A request cancelled while waiting is not a failure the caller needs to
    // hear about; the screen that cancelled it has already moved on.
    if (options.cancelToken?.isCancelled ?? false) {
      handler.next(err.copyWith(type: DioExceptionType.cancel));
      return;
    }

    // Re-dispatch through the original client rather than recursing here: that
    // runs the whole interceptor chain again, so the next failure arrives back
    // here and consumes another attempt from the same budget, exactly as it
    // would have without the retry.
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    final options = err.requestOptions;

    final method = options.method.toUpperCase();
    final explicitlySafe =
        options.extra['safe_to_retry'] == true ||
        options.headers['X-Safe-Retry'] == 'true';
    if (!_safeMethods.contains(method) && !explicitlySafe) return false;

    final status = err.response?.statusCode;
    if (status != null) return _retryableStatuses.contains(status);

    // No response at all: the request never reached the server, so it is safe
    // to send again by definition.
    return err.type != DioExceptionType.cancel;
  }

  Duration _exponential(int attempt) {
    final ms = _baseDelay.inMilliseconds * (1 << (attempt - 1));
    return Duration(
      milliseconds: ms > _maxDelay.inMilliseconds ? _maxDelay.inMilliseconds : ms,
    );
  }

  /// Reads `Retry-After`, which is either delta-seconds or an HTTP-date.
  ///
  /// Delegates to [parseRetryAfterSeconds] so the delay this waits and the
  /// number reported on [TooManyRequestsException] cannot disagree -- two
  /// copies of the parser would eventually drift, and the symptom would be a
  /// terminal that tells the user to wait 30 seconds and then waits 2.
  Duration? _retryAfter(DioException err) {
    final headers = err.response?.headers;
    if (headers == null) return null;

    final seconds = parseRetryAfterSeconds(headers.value('retry-after'));
    if (seconds == null) return null;

    // Capped like the exponential backoff, so a server asking for an hour of
    // patience cannot park a till in a sleep that looks like a hang.
    if (seconds > _maxDelay.inSeconds) return _maxDelay;

    return Duration(seconds: seconds);
  }
}