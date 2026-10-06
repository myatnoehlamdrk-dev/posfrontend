import 'package:flutter/foundation.dart';

import 'package:posfrontend/core/auth/terminal_identity.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/features/auth/domain/entities/login_result.dart';
import 'package:posfrontend/features/auth/domain/entities/user.dart';
import 'package:posfrontend/features/auth/domain/usecases/login.dart';
import 'package:posfrontend/shared/services/fcm_service.dart';

class LoginViewModel extends BaseViewModel with FormValidationMixin {
  final LoginUseCase _loginUseCase;

  LoginViewModel({required LoginUseCase loginUseCase})
    : _loginUseCase = loginUseCase;

  String _email = '';
  String _password = '';
  UserEntity? _user;
  String _accessToken = '';

  String get email => _email;
  String get password => _password;
  UserEntity? get user => _user;
  String get accessToken => _accessToken;

  void setEmail(String value) {
    _email = value;
    clearFieldError('email');
  }

  void setPassword(String value) {
    _password = value;
    clearFieldError('password');
  }

  bool validate() {
    clearAllFieldErrors();

    if (_email.trim().isEmpty) {
      setFieldError('email', 'Email is required');
    } else if (!isValidEmail(_email)) {
      setFieldError('email', 'Enter a valid email');
    }
    if (_password.isEmpty) {
      setFieldError('password', 'Password is required');
    }

    notifyListeners();
    return fieldErrors.isEmpty;
  }

  Future<LoginResult?> login() async {
    resetError();
    if (!validate()) {
      setError('Please complete all required fields');
      return null;
    }

    setLoading(true);
    try {
      final result = await _loginUseCase(
        LoginParams(
          email: _email.trim(),
          password: _password,
          // Labels the session server-side so an admin can tell which till is
          // signed in and revoke just that device.
          deviceName: await TerminalIdentity.label(),
        ),
      );
      _user = result.user;
      _accessToken = result.accessToken;
      await TokenStorage.saveToken(result.accessToken);

      // Register FCM token after successful authentication
      await _registerFcmToken();

      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      final fcmService = getIt<FcmService>();
      await fcmService.registerTokenAfterLogin();
    } catch (e) {
      // FCM registration failure should not block login
      debugPrint('FCM token registration failed: $e');
    }
  }
}
