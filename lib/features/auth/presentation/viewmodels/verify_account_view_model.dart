import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/features/auth/domain/usecases/verify_account.dart';

class VerifyAccountViewModel extends BaseViewModel with FormValidationMixin {
  final SendOtpUseCase _sendOtpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;

  VerifyAccountViewModel({
    required SendOtpUseCase sendOtpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
  })  : _sendOtpUseCase = sendOtpUseCase,
        _verifyOtpUseCase = verifyOtpUseCase;

  String _email = '';
  String _otp = '';

  String get email => _email;
  String get otp => _otp;

  void setEmail(String value) { _email = value; clearFieldError('email'); }
  void setOtp(String value) { _otp = value; clearFieldError('otp'); }

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
      await _sendOtpUseCase(SendOtpParams(email: _email.trim()));
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
      await _verifyOtpUseCase(VerifyOtpParams(email: _email.trim(), otp: _otp.trim()));
      return true;
    } catch (e) {
      setError('Verification failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
