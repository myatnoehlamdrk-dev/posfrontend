import 'package:flutter/material.dart';
import 'package:posfrontend/modules/forgot_password/repository/forgot_password_repository_impl.dart';
import 'package:posfrontend/modules/forgot_password/view/reset_password_screen.dart';
import 'package:posfrontend/modules/forgot_password/viewmodel/forgot_password_view_model.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/required_label.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  late final ForgotPasswordViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ForgotPasswordViewModel(
      repository: ForgotPasswordRepositoryImpl(),
    );
    _emailController.addListener(() => _viewModel.setEmail(_emailController.text));
    _otpController.addListener(() => _viewModel.setOtp(_otpController.text));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final success = await _viewModel.sendOtp();
    if (success && mounted) {
      showSuccessSnackBar(context, 'OTP sent to your email');
    }
  }

  Future<void> _handleVerifyOtp() async {
    final success = await _viewModel.verifyOtp();
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: _viewModel.email,
            resetToken: _viewModel.resetToken,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final errors = _viewModel.fieldErrors;
        final loading = _viewModel.isLoading;
        final otpSent = _viewModel.otpSent;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeaderIcon(),
                    const SizedBox(height: 20),
                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.labelColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      otpSent
                          ? 'Enter the OTP sent to your email'
                          : 'Enter your email to receive a verification code',
                      style: const TextStyle(
                        color: AppColors.hintColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RequiredLabel('Email'),
                    ),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !otpSent,
                      decoration: appInputDecoration(
                        icon: Icons.email_outlined,
                        hint: 'Enter your email',
                        errorText: errors['email'],
                      ),
                    ),
                    if (!otpSent) ...[
                      const SizedBox(height: 24),
                      GradientButton(
                        label: 'Send OTP',
                        loading: loading,
                        onPressed: _handleSendOtp,
                      ),
                    ],
                    if (otpSent) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RequiredLabel('OTP Code'),
                      ),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        maxLength: 6,
                        decoration: appInputDecoration(
                          icon: Icons.pin_outlined,
                          hint: 'Enter 6-digit OTP',
                          errorText: errors['otp'],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: loading ? null : _handleSendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        label: 'Verify OTP',
                        loading: loading,
                        onPressed: _handleVerifyOtp,
                      ),
                    ],
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
                    _buildBackToLogin(),
                  ],
                ),
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

  Widget _buildBackToLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Remember your password?',
          style: TextStyle(color: AppColors.hintColor, fontSize: 14),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.pop(context),
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
    );
  }
}
