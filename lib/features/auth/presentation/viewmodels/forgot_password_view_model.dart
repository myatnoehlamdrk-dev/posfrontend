import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/features/auth/domain/usecases/forgot_password.dart';

class ForgotPasswordViewModel extends BaseViewModel with FormValidationMixin {
  final SendForgotPasswordOtpUseCase _sendOtpUseCase;
  final VerifyForgotPasswordOtpUseCase _verifyOtpUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordViewModel({
    required SendForgotPasswordOtpUseCase sendOtpUseCase,
    required VerifyForgotPasswordOtpUseCase verifyOtpUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  })  : _sendOtpUseCase = sendOtpUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _resetPasswordUseCase = resetPasswordUseCase;

  String _email = '';
  String _otp = '';
  String _newPassword = '';
  String _confirmPassword = '';
  String _resetToken = '';
  bool _otpSent = false;
  bool _otpVerified = false;

  String get email => _email;
  String get otp => _otp;
  String get resetToken => _resetToken;
  bool get otpSent => _otpSent;
  bool get otpVerified => _otpVerified;

  void setEmail(String value) { _email = value; clearFieldError('email'); }
  void setOtp(String value) { _otp = value; clearFieldError('otp'); }
  void setNewPassword(String value) { _newPassword = value; clearFieldError('password'); }
  void setConfirmPassword(String value) { _confirmPassword = value; clearFieldError('password_confirmation'); }
  void setResetToken(String value) { _resetToken = value; }

  bool _validateEmail() {
    clearAllFieldErrors();
    if (_email.trim().isEmpty) {
      setFieldError('email', 'Email is required');
    } else if (!isValidEmail(_email)) {
      setFieldError('email', 'Enter a valid email');
    }
    notifyListeners();
    return !fieldErrors.containsKey('email');
  }

  bool _validateOtp() {
    clearFieldError('otp');
    if (_otp.trim().isEmpty) {
      setFieldError('otp', 'OTP is required');
    } else if (_otp.trim().length != 6) {
      setFieldError('otp', 'OTP must be 6 digits');
    }
    notifyListeners();
    return !fieldErrors.containsKey('otp');
  }

  bool _validatePassword() {
    clearAllFieldErrors();
    if (_newPassword.isEmpty) {
      setFieldError('password', 'Password is required');
    } else if (_newPassword.length < 6) {
      setFieldError('password', 'Password must be at least 6 characters');
    }
    if (_confirmPassword.isEmpty) {
      setFieldError('password_confirmation', 'Please confirm your password');
    } else if (_newPassword != _confirmPassword) {
      setFieldError('password_confirmation', 'Passwords do not match');
    }
    notifyListeners();
    return fieldErrors.isEmpty;
  }

  Future<bool> sendOtp() async {
    resetError();
    clearAllFieldErrors();
    if (!_validateEmail()) return false;

    setLoading(true);
    try {
      await _sendOtpUseCase(SendOtpParams(email: _email.trim()));
      _otpSent = true;
      notifyListeners();
      return true;
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
    if (!_validateOtp()) return false;

    setLoading(true);
    try {
      _resetToken = await _verifyOtpUseCase(VerifyOtpParams(email: _email.trim(), otp: _otp.trim()));
      _otpVerified = true;
      notifyListeners();
      return true;
    } catch (e) {
      setError('OTP verification failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> resetPassword() async {
    resetError();
    clearAllFieldErrors();
    if (!_validatePassword()) return false;

    setLoading(true);
    try {
      await _resetPasswordUseCase(ResetPasswordParams(
        email: _email.trim(),
        resetToken: _resetToken,
        password: _newPassword,
      ));
      return true;
    } catch (e) {
      setError('Password reset failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  void reset() {
    _email = '';
    _otp = '';
    _newPassword = '';
    _confirmPassword = '';
    _resetToken = '';
    _otpSent = false;
    _otpVerified = false;
    clearAllFieldErrors();
    resetError();
    notifyListeners();
  }
}
