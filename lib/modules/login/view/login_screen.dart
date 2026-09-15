import 'package:flutter/material.dart';
import 'package:posfrontend/modules/forgot_password/view/forgot_password_screen.dart';
import 'package:posfrontend/modules/login/repository/login_repository_impl.dart';
import 'package:posfrontend/modules/login/viewmodel/login_view_model.dart';
import 'package:posfrontend/modules/dashboard/view/dashboard_screen.dart';
import 'package:posfrontend/modules/shop/view/shop_screen.dart';
import 'package:posfrontend/modules/verify_account/view/verify_account_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/required_label.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final LoginViewModel _viewModel;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(loginRepository: LoginRepositoryImpl());

    _emailController.addListener(() => _viewModel.setEmail(_emailController.text));
    _passwordController
        .addListener(() => _viewModel.setPassword(_passwordController.text));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final response = await _viewModel.login();
    if (response != null && mounted) {
      AuthScope.updateUserOf(context, response);
      ShopScope.loadShop(context, shopId: response.shopId);
      showSuccessSnackBar(context, 'Login successful');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
                      'Welcome Back!',
                      style: TextStyle(
                        color: AppColors.labelColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please login to your account',
                      style: TextStyle(
                        color: AppColors.hintColor,
                        fontSize: 14,
                      ),
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
                      decoration: appInputDecoration(
                        icon: Icons.email_outlined,
                        hint: 'Enter your email',
                        errorText: errors['email'],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RequiredLabel('Password'),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: appInputDecoration(
                        icon: Icons.lock_outline,
                        hint: 'Enter your password',
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Login',
                      loading: loading,
                      onPressed: _submit,
                    ),
                    if (_viewModel.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            Text(
                              _viewModel.errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_viewModel.errorMessage!.contains('verify'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VerifyAccountScreen(
                                          email: _emailController.text,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Verify Email',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildRegisterPrompt(),
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
      height: 220,
      width: 220,
      fit: BoxFit.contain,
    );
  }

  Widget _buildDivider() {
    return Row(
      children: const [
        Expanded(child: Divider(color: AppColors.borderColor)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(color: AppColors.hintColor, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AppColors.borderColor)),
      ],
    );
  }

  Widget _buildRegisterPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(color: AppColors.hintColor, fontSize: 14),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopScreen()),
            );
          },
          child: const Text(
            'Register',
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
