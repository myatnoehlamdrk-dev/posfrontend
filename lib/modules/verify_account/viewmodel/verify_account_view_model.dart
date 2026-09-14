import 'package:dio/dio.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/verify_account/repository/verify_account_repository.dart';

class VerifyAccountViewModel extends BaseViewModel with FormValidationMixin {
  final VerifyAccountRepository _repository;

  VerifyAccountViewModel({required VerifyAccountRepository repository})
      : _repository = repository;

  String _email = '';
  String _otp = '';

  String get email => _email;
  String get otp => _otp;

  void setEmail(String value) {
    _email = value;
    clearFieldError('email');
  }

  void setOtp(String value) {
    _otp = value;
    clearFieldError('otp');
  }

  bool _validateOtp() {
    clearAllFieldErrors();
    if (_otp.trim().isEmpty) {
      setFieldError('otp', 'OTP is required');
    } else if (_otp.trim().length != 6) {
      setFieldError('otp', 'OTP must be 6 digits');
    }
    notifyListeners();
    return !fieldErrors.containsKey('otp');
  }

  Future<bool> sendOtp() async {
    resetError();
    clearAllFieldErrors();

    setLoading(true);
    try {
      await _repository.sendOtp(_email.trim(), cancelToken: cancelToken);
      return true;
    } on DioException catch (e) {
      final errors = extractFieldErrors(e);
      if (errors.isNotEmpty) {
        errors.forEach((key, value) => setFieldError(key, value));
        notifyListeners();
      }
      setError(e.response?.data?['message']?.toString() ?? 'Failed to send OTP');
      return false;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Failed to send OTP: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> verifyOtp() async {
    resetError();
    clearAllFieldErrors();
    if (!_validateOtp()) {
      return false;
    }

    setLoading(true);
    try {
      await _repository.verifyOtp(_email.trim(), _otp.trim(), cancelToken: cancelToken);
      return true;
    } on DioException catch (e) {
      final errors = extractFieldErrors(e);
      if (errors.isNotEmpty) {
        errors.forEach((key, value) => setFieldError(key, value));
        notifyListeners();
      }
      setError(e.response?.data?['message']?.toString() ?? 'Verification failed');
      return false;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Verification failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
