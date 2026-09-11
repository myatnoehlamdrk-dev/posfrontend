import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';

String formatApiError(Object e) {
  if (e is ApiException) return e.message;
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        return ApiException.fromDio(e).message;
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        return 'Network error. Please try again.';
    }
  }
  if (e is SocketException) return 'No internet connection.';
  if (e is TimeoutException) return 'Request timed out. Please try again.';
  if (e is FormatException) return 'Invalid data received from server.';
  return 'An unexpected error occurred.';
}
