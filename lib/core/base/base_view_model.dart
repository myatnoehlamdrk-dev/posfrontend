import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:posfrontend/core/auth/auth_redirect.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  final CancelToken _cancelToken = CancelToken();
  CancelToken get cancelToken => _cancelToken;

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void resetError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Run an async action with automatic error handling.
  /// Returns null on error (error message is set via setError).
  Future<T?> runAsync<T>(
    Future<T> Function(CancelToken token) action, {
    bool showLoading = true,
    String? errorPrefix,
  }) async {
    try {
      if (showLoading) setLoading(true);
      resetError();
      return await action(_cancelToken);
    } on CancelledException {
      return null;
    } on AuthException {
      await redirectToLogin();
      return null;
    } on TimeoutException catch (e) {
      setError(e.message);
      return null;
    } on NetworkException catch (e) {
      setError(e.message);
      return null;
    } on ValidationException catch (e) {
      setError(e.message);
      return null;
    } on ServerException catch (e) {
      setError(e.message);
      return null;
    } on ApiException catch (e) {
      setError(errorPrefix != null ? '$errorPrefix: ${e.message}' : e.message);
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return null;
      final appException = fromDioException(e);
      if (appException is AuthException) {
        await redirectToLogin();
        return null;
      }
      setError(errorPrefix != null ? '$errorPrefix: ${appException.message}' : appException.message);
      return null;
    } catch (e) {
      setError(errorPrefix != null ? '$errorPrefix: $e' : e.toString());
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  @override
  void dispose() {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel();
    }
    _isLoading = false;
    _errorMessage = null;
    super.dispose();
  }
}
