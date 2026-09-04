import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

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

  Future<T?> runAsync<T>(
    Future<T> Function() action, {
    bool showLoading = true,
    String? errorPrefix,
  }) async {
    try {
      if (showLoading) setLoading(true);
      resetError();
      return await action();
    } catch (e) {
      setError(errorPrefix != null ? '$errorPrefix: $e' : e.toString());
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  @override
  void dispose() {
    _isLoading = false;
    _errorMessage = null;
    super.dispose();
  }
}
