import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/login/model/login_request.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/login/repository/login_repository.dart';

class LoginViewModel extends BaseViewModel {
  final LoginRepository _loginRepository;

  LoginViewModel({required LoginRepository loginRepository})
      : _loginRepository = loginRepository;

  String _email = '';
  String _password = '';

  String get email => _email;
  String get password => _password;

  final Map<String, String?> _fieldErrors = {};
  Map<String, String?> get fieldErrors => Map.unmodifiable(_fieldErrors);

  void setEmail(String value) {
    _email = value;
    _clearError('email');
  }

  void setPassword(String value) {
    _password = value;
    _clearError('password');
  }

  void _clearError(String key) {
    if (_fieldErrors.containsKey(key)) {
      _fieldErrors.remove(key);
      notifyListeners();
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  bool validate() {
    _fieldErrors.clear();

    if (_email.trim().isEmpty) {
      _fieldErrors['email'] = 'Email is required';
    } else if (!_isValidEmail(_email)) {
      _fieldErrors['email'] = 'Enter a valid email';
    }
    if (_password.isEmpty) {
      _fieldErrors['password'] = 'Password is required';
    }

    notifyListeners();
    return _fieldErrors.isEmpty;
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
