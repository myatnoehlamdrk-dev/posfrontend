import 'package:flutter/material.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/features/auth/domain/usecases/forgot_password.dart';
import 'package:posfrontend/features/auth/presentation/viewmodels/forgot_password_view_model.dart';
import 'package:posfrontend/features/auth/presentation/screens/login_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/required_label.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final ForgotPasswordViewModel _viewModel;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _viewModel = ForgotPasswordViewModel(
      sendOtpUseCase: getIt<SendForgotPasswordOtpUseCase>(),
      verifyOtpUseCase: getIt<VerifyForgotPasswordOtpUseCase>(),
      resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
    );
    _viewModel.setEmail(widget.email);
    _viewModel.setResetToken(widget.resetToken);
    _passwordController.addListener(() => _viewModel.setNewPassword(_passwordController.text));
    _confirmPasswordController.addListener(() => _viewModel.setConfirmPassword(_confirmPasswordController.text));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final success = await _viewModel.resetPassword();
    if (success && mounted) {
      showSuccessSnackBar(context, 'Password reset successful!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
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
                      'Reset Password',
                      style: TextStyle(
                        color: AppColors.labelColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new password for ${widget.email}',
                      style: const TextStyle(
                        color: AppColors.hintColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RequiredLabel('New Password'),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: appInputDecoration(
                        icon: Icons.lock_outline,
                        hint: 'Enter new password',
                        errorText: errors['password'],
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.hintColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RequiredLabel('Confirm Password'),
                    ),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleResetPassword(),
                      decoration: appInputDecoration(
                        icon: Icons.lock_outline,
                        hint: 'Confirm new password',
                        errorText: errors['password_confirmation'],
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.hintColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      label: 'Reset Password',
                      loading: loading,
                      onPressed: _handleResetPassword,
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
