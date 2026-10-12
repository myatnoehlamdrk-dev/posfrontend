import 'dart:io';

import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';

/// Converts any exception to a user-friendly message.
String formatApiError(Object e) {
  if (e is AppException) return e.message;
  if (e is DioException) return fromDioException(e).message;
  if (e is SocketException) {
    return 'Network connection failed.';
  }
  if (e is TimeoutException) return 'Network connection timed out.';
  if (e is FormatException) return 'Invalid data received from server.';
  return 'An unexpected error occurred.';
}
