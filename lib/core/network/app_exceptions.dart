import 'package:dio/dio.dart';

/// Base exception for all API/network errors.
/// Each subtype gets different UI treatment.
sealed class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// No internet connection.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
  });
}

/// API request timed out (connect/send/receive).
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out. Please try again.',
  });
}

/// Auth token expired or invalid — redirect to login.
class AuthException extends AppException {
  const AuthException({
    super.message = 'Session expired. Please login again.',
    super.statusCode = 401,
  });
}

/// Server returned 422 with field-level validation errors.
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException({
    super.message = 'Please fix the errors below.',
    super.statusCode = 422,
    this.fieldErrors = const {},
  });
}

/// Server error (500, 502, 503, etc.).
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error. Please try again later.',
    super.statusCode,
  });
}

/// Authenticated, but not allowed to do this. Distinct from [AuthException]
/// because it must not clear the token: the session is valid, the request
/// simply was not permitted, and logging the user out would lose their cart.
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = "You don't have permission to do this.",
    super.statusCode = 403,
  });
}

/// Rate limited. [retryAfterSeconds] is the wait parsed from the standard
/// `Retry-After` header, or null when the server did not send a usable one.
class TooManyRequestsException extends AppException {
  final int? retryAfterSeconds;

  /// Not const, unlike its siblings: it interpolates the wait into the
  /// message, and a const constructor cannot call a function. Callers read the
  /// result through the inherited [message], which is all any error surface
  /// uses anyway.
  TooManyRequestsException({
    String? message,
    this.retryAfterSeconds,
  }) : super(
         message: message ?? _rateLimitMessage(retryAfterSeconds),
         statusCode: 429,
       );

  /// The wait is baked into the message rather than left to the UI to compose,
  /// because every surface that shows an error already renders `message` and
  /// none of them know about rate limiting. Null reads better than "in 0
  /// seconds", so an absent header gets no number at all.
  static String _rateLimitMessage(int? seconds) {
    if (seconds == null || seconds <= 0) {
      return 'Too many attempts. Please try again later.';
    }
    if (seconds < 60) {
      return 'Too many attempts. Try again in ${seconds}s.';
    }
    final minutes = (seconds / 60).ceil();
    return 'Too many attempts. Try again in $minutes minute${minutes == 1 ? '' : 's'}.';
  }
}

/// Request was cancelled by the user navigating away.
class CancelledException extends AppException {
  const CancelledException() : super(message: 'Request cancelled.');
}

/// Generic API exception for unhandled status codes.
class ApiException extends AppException {
  const ApiException({super.statusCode, required super.message});

  /// Backward-compatible static method.
  static AppException fromDio(DioException e) => fromDioException(e);
}

/// Unexpected/unknown error.
class UnknownException extends AppException {
  const UnknownException({super.message = 'An unexpected error occurred.'});
}

/// Centralized DioException → AppException conversion.
AppException fromDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutException();
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.cancel:
      return const CancelledException();
    case DioExceptionType.badResponse:
      return _fromBadResponse(e);
    default:
      return const UnknownException();
  }
}

AppException _fromBadResponse(DioException e) {
  final statusCode = e.response?.statusCode;
  final data = e.response?.data;

  var message = 'Server error occurred.';
  if (data is Map<String, dynamic>) {
    if (data['message'] != null) message = data['message'].toString();
    if (data['error'] != null) message = data['error'].toString();
  }

  switch (statusCode) {
    case 401:
      return AuthException(message: message);
    case 403:
      return ForbiddenException(message: message);
    case 429:
      return TooManyRequestsException(
        message: message,
        retryAfterSeconds: parseRetryAfterSeconds(
          e.response?.headers.value('retry-after'),
        ),
      );
    case 422:
      final fieldErrors = <String, String>{};
      if (data is Map<String, dynamic> && data['errors'] is Map) {
        final errors = data['errors'] as Map<String, dynamic>;
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            fieldErrors[key] = value.first.toString();
          }
        });
      }
      return ValidationException(message: message, fieldErrors: fieldErrors);
    case 500:
    case 502:
    case 503:
      return ServerException(message: message, statusCode: statusCode);
    default:
      return ApiException(statusCode: statusCode, message: message);
  }
}

/// Parses the standard `Retry-After` header into whole seconds.
///
/// Returns null for anything unusable: an absent header, an unparseable value,
/// or an HTTP-date that has already passed. Callers treat null as "no
/// information" and fall back to their own backoff, which is safer than
/// trusting a stale date to mean "retry immediately".
int? parseRetryAfterSeconds(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;

  final seconds = int.tryParse(value);
  if (seconds != null) return seconds < 0 ? 0 : seconds;

  final until = _parseHttpDate(value);
  if (until == null) return null;

  final wait = until.difference(DateTime.now()).inSeconds;
  return wait < 0 ? 0 : wait;
}

/// Reads the HTTP-date form of `Retry-After`.
///
/// Hand-rolled rather than `DateTime.parse`, which returns null for the format
/// every RFC 9110 server actually emits: `Wed, 21 Oct 2015 07:28:00 GMT`. That
/// silently reduced this header to its delta-seconds form alone, so a server
/// that reports a reset window as a date got treated as having sent nothing at
/// all.
///
/// Written in plain Dart instead of `dart:io`'s `HttpDate`, which it used to
/// delegate to: on the web build `HttpDate.parse` throws `UnsupportedError`,
/// a type the old catches did not cover, so a 429 carrying an HTTP-date broke
/// the request path precisely when `throttle:auth` was being hit repeatedly.
/// `HttpDate` also misreads the obsoleted RFC 850 two-digit year; nothing
/// emits that format, so rejecting it outright is the right trade.
DateTime? _parseHttpDate(String value) {
  final match = _imfFixdate.firstMatch(value.trim());
  if (match == null) return null;

  final month = _httpMonths[match.group(2)];
  if (month == null) return null;

  try {
    return DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  } on ArgumentError {
    // A syntactically valid date that is out of range for its field (a
    // 31st of February, an hour of 99). No information beats a wrong one.
    return null;
  }
}

/// IMF-fixdate: `Wed, 21 Oct 2015 07:28:00 GMT`.
final RegExp _imfFixdate = RegExp(
  r'^[A-Z][a-z]{2}, (\d{2}) ([A-Z][a-z]{2}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
);

const Map<String, int> _httpMonths = {
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};

/// Helper to extract field-level validation errors from a DioException.
/// Centralized — no more duplication across repositories.
Map<String, String> extractFieldErrors(DioException e) {
  final fieldErrors = <String, String>{};
  final data = e.response?.data;
  if (data is Map<String, dynamic> && data['errors'] is Map) {
    final errors = data['errors'] as Map<String, dynamic>;
    errors.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        fieldErrors[key] = value.first.toString();
      }
    });
  }
  return fieldErrors;
}
