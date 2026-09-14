import 'dart:io';

import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';

/// Converts any exception to a user-friendly message.
String formatApiError(Object e) {
  if (e is AppException) return e.message;
  if (e is DioException) return fromDioException(e).message;
  if (e is SocketException) return 'No internet connection. Please check your network.';
  if (e is TimeoutException) return 'Request timed out. Please try again.';
  if (e is FormatException) return 'Invalid data received from server.';
  return 'An unexpected error occurred.';
}
