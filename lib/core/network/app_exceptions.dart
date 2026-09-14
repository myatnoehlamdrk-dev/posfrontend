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
  const NetworkException({super.message = 'No internet connection. Please check your network.'});
}

/// API request timed out (connect/send/receive).
class TimeoutException extends AppException {
  const TimeoutException({super.message = 'Request timed out. Please try again.'});
}

/// Auth token expired or invalid — redirect to login.
class AuthException extends AppException {
  const AuthException({super.message = 'Session expired. Please login again.', super.statusCode = 401});
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
  const ServerException({super.message = 'Server error. Please try again later.', super.statusCode});
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
