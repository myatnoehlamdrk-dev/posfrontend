import 'package:flutter/material.dart';
import 'package:posfrontend/modules/login/view/login_screen.dart';
import 'package:posfrontend/modules/verify_account/repository/verify_account_repository_impl.dart';
import 'package:posfrontend/modules/verify_account/viewmodel/verify_account_view_model.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/required_label.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class VerifyAccountScreen extends StatefulWidget {
  final String email;

  const VerifyAccountScreen({super.key, required this.email});

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final _otpController = TextEditingController();

  late final VerifyAccountViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VerifyAccountViewModel(
      repository: VerifyAccountRepositoryImpl(),
    );
    _viewModel.setEmail(widget.email);
    _otpController.addListener(() => _viewModel.setOtp(_otpController.text));

    // Auto-send OTP on screen load
    _viewModel.sendOtp();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final success = await _viewModel.verifyOtp();
    if (success && mounted) {
      showSuccessSnackBar(context, 'Email verified! You can now login.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleResendOtp() async {
    final success = await _viewModel.sendOtp();
    if (success && mounted) {
      showSuccessSnackBar(context, 'OTP sent to your email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final errors = _viewModel.fieldErrors;
        final loading = _viewModel.isLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeaderIcon(),
                  const SizedBox(height: 20),
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      color: AppColors.labelColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit verification code to',
                    style: const TextStyle(
                      color: AppColors.hintColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RequiredLabel('Verification Code'),
                  ),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    onFieldSubmitted: (_) => _handleVerify(),
                    decoration: appInputDecoration(
                      icon: Icons.pin_outlined,
                      hint: 'Enter 6-digit code',
                      errorText: errors['otp'],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: loading ? null : _handleResendOtp,
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Verify',
                    loading: loading,
                    onPressed: _handleVerify,
                  ),
                  if (_viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _viewModel.errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already verified?',
                        style: TextStyle(color: AppColors.hintColor, fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderIcon() {
    return Image.asset(
      'assets/shop.png',
      height: 180,
      width: 180,
      fit: BoxFit.contain,
    );
  }
}
