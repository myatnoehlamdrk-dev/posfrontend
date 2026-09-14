import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/login/model/login_request.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/login/repository/login_repository.dart';

class LoginViewModel extends BaseViewModel with FormValidationMixin {
  final LoginRepository _loginRepository;

  LoginViewModel({required LoginRepository loginRepository})
      : _loginRepository = loginRepository;

  String _email = '';
  String _password = '';

  String get email => _email;
  String get password => _password;

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

  Future<LoginResponse?> login() async {
    resetError();
    if (!validate()) {
      setError('Please complete all required fields');
      return null;
    }

    setLoading(true);
    try {
      final response = await _loginRepository.login(
        LoginRequest(
          email: _email.trim(),
          password: _password,
        ),
        cancelToken: cancelToken,
      );
      await TokenStorage.saveToken(response.accessToken);
      return response;
    } on ApiException catch (e) {
      setError(e.message);
      return null;
    } catch (e) {
      setError('Login failed: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }
}
