import 'package:flutter/foundation.dart';

import 'package:posfrontend/core/auth/terminal_identity.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
import 'package:posfrontend/features/auth/domain/entities/login_result.dart';
import 'package:posfrontend/features/auth/domain/entities/user.dart';
import 'package:posfrontend/features/auth/domain/usecases/login.dart';
import 'package:posfrontend/features/settings/presentation/server_preferences.dart';
import 'package:posfrontend/shared/services/fcm_service.dart';

class LoginViewModel extends BaseViewModel with FormValidationMixin {
  final LoginUseCase _loginUseCase;

  LoginViewModel({required LoginUseCase loginUseCase})
    : _loginUseCase = loginUseCase;

  String _email = '';
  String _password = '';
  UserEntity? _user;
  String _accessToken = '';

  /// Set when login was refused because the shop has not decided on this
  /// account yet. The screen routes to the approval screen instead of showing
  /// an error banner; a rejected request is carried here too, with [rejected]
  /// telling the screen which copy to use.
  MembershipPendingException? _pendingRequest;

  String get email => _email;
  String get password => _password;
  UserEntity? get user => _user;
  String get accessToken => _accessToken;
  MembershipPendingException? get pendingRequest => _pendingRequest;

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
    // A retry must not keep showing an older decision. The screen reuses this
    // ViewModel for "Try again" on the approval screen, so a stale pending
    // value here would bounce a now-approved account back to that screen.
    _pendingRequest = null;
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

      // Bring the shop's saved theme and language across with the session.
      // These used to load only when the Settings screen opened, so a till
      // that never visited Settings kept whatever it had locally. Awaited so
      // the dashboard's first frame is already in the right theme and
      // language; the helper is time-boxed and swallows its own failures.
      await syncServerPreferences();

      return result;
    } on MembershipPendingException catch (e) {
      // Not a failed login: the credentials were accepted, only membership is
      // outstanding. No token was issued, so there is nothing to revoke.
      _pendingRequest = e;
      return null;
    } catch (e) {
      setError(formatApiError(e));
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
