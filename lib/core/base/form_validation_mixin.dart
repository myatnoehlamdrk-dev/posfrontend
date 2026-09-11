import 'package:flutter/foundation.dart';

mixin FormValidationMixin on ChangeNotifier {
  final Map<String, String?> _fieldErrors = {};
  Map<String, String?> get fieldErrors => Map.unmodifiable(_fieldErrors);

  void clearAllFieldErrors() {
    _fieldErrors.clear();
  }

  void clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      _fieldErrors.remove(key);
      notifyListeners();
    }
  }

  void setFieldError(String key, String message) {
    _fieldErrors[key] = message;
  }

  String? getFieldError(String key) => _fieldErrors[key];

  bool isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }
}
