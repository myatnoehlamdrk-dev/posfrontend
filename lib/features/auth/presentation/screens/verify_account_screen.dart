import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/features/auth/domain/usecases/verify_account.dart';
import 'package:posfrontend/features/auth/presentation/viewmodels/verify_account_view_model.dart';
import 'package:posfrontend/features/auth/presentation/screens/login_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/app_page_transitions.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/required_label.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

/// Layout thresholds, matching the other auth screens so a window flips to the
/// desktop treatment in the same place everywhere.
///
/// This screen has no brand pane to split with — it is one short form — so
/// "desktop" means the form is lifted onto a capped card instead of stretching
/// across the window. The extra pane the other auth screens use would be
/// decoration here, not information.
class _VerifyLayout {
  _VerifyLayout._();

  static const double cardFrom = 600;
  static const double formMaxWidth = 440;
  static const double cardMaxWidth = 460;
  static const double cardPadding = 32;
}

class VerifyAccountScreen extends StatefulWidget {
  final String email;

  /// Whether to request a code as the screen opens.
  ///
  /// The register flow already mails a code the moment the account is
  /// created, so auto-resending here put two "Verify your email address"
  /// mails in the inbox for every sign-up. The login flow -- an unverified
  /// account trying to sign in -- has no fresh code in the air, so it keeps
  /// the auto-send.
  final bool sendOnOpen;

  const VerifyAccountScreen({
    super.key,
    required this.email,
    this.sendOnOpen = true,
  });

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
      sendOtpUseCase: getIt<SendOtpUseCase>(),
      verifyOtpUseCase: getIt<VerifyOtpUseCase>(),
    );
    _viewModel.setEmail(widget.email);
    _otpController.addListener(() => _viewModel.setOtp(_otpController.text));

    if (widget.sendOnOpen) {
      _viewModel.sendOtp();
    }
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
        AppPageTransitions.fade<void>(const LoginScreen()),
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
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final carded = constraints.maxWidth >= _VerifyLayout.cardFrom;
                return _centeredScroll(
                  maxWidth: carded
                      ? _VerifyLayout.cardMaxWidth
                      : _VerifyLayout.formMaxWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeaderIcon(),
                      const SizedBox(height: 20),
                      _buildHeading(),
                      const SizedBox(height: 28),
                      if (carded)
                        _card(
                          child: _buildForm(errors: errors, loading: loading),
                        )
                      else
                        _buildForm(errors: errors, loading: loading),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeading() {
    final p = context.palette;
    return Column(
      children: [
        Text(
          context.l10n.t('Verify Your Email'),
          style: TextStyle(
            color: p.textPrimary,
            fontSize: AppTypography.displaySmallSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.t('We sent a 6-digit verification code to'),
          style: TextStyle(
            color: p.textMuted,
            fontSize: AppTypography.bodySmallSize,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          widget.email,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: AppTypography.bodySmallSize,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm({
    required Map<String, String?> errors,
    required bool loading,
  }) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
            context,
            icon: Icons.pin_outlined,
            hint: context.l10n.t('Enter 6-digit code'),
            errorText: errors['otp'],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: loading ? null : _handleResendOtp,
            child: Text(
              context.l10n.t('Resend Code'),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: AppTypography.labelMediumSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: context.l10n.t('Verify'),
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
                fontSize: AppTypography.labelMediumSize,
              ),
            ),
          ),
        const SizedBox(height: 24),
        // Wrap rather than Row: translated prompts run long and would overflow
        // on a phone instead of wrapping.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 2,
          children: [
            Text(
              context.l10n.t('Already verified?'),
              style: TextStyle(
                color: p.textMuted,
                fontSize: AppTypography.bodySmallSize,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                AppPageTransitions.authSmooth<void>(const LoginScreen()),
              ),
              child: Text(
                context.l10n.t('Back to Login'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: AppTypography.bodySmallSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Scrolls when the content is taller than the window, centres when it is
  /// not. The `minHeight` floor is what makes those two agree.
  Widget _centeredScroll({
    required Widget child,
    required double maxWidth,
    required EdgeInsets padding,
  }) {
    return LayoutBuilder(
      builder: (ctx, c) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: c.maxHeight - padding.vertical,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// The desktop surface: same fill, radius, border and shadow as the login and
  /// reset cards, so the form looks like the same object on every auth page.
  Widget _card({required Widget child}) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_VerifyLayout.cardPadding),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeaderIcon() {
    return Image.asset(
      'assets/shop.png',
      height: 180,
      width: 180,
      fit: BoxFit.contain,
      cacheWidth: 540,
      cacheHeight: 540,
    );
  }
}
