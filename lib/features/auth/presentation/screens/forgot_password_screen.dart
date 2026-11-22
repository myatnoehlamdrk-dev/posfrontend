import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/features/auth/domain/usecases/forgot_password.dart';
import 'package:posfrontend/features/auth/presentation/viewmodels/forgot_password_view_model.dart';
import 'package:posfrontend/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/app_page_transitions.dart';
import 'package:posfrontend/shared/widgets/brand_art_veil.dart';
import 'package:posfrontend/shared/widgets/brand_avatar_badge.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/required_label.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

/// Layout thresholds, matching the login screen so the two agree.
///
///  * phone   (< [cardFrom])  — single column, edge to edge, no surface.
///  * tablet+ (>= [cardFrom]) — lifted onto a card, because the alternative is
///    an email input stretched across 1900px of desktop window.
class _ForgotLayout {
  static const double cardFrom = 600;
  static const double splitFrom = 900;
  static const double formMaxWidth = 440;
  static const double cardMaxWidth = 460;
  static const double cardPadding = 32;
  static const double panePadding = 40;
}

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
      sendOtpUseCase: getIt<SendForgotPasswordOtpUseCase>(),
      verifyOtpUseCase: getIt<VerifyForgotPasswordOtpUseCase>(),
      resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
    );
    _emailController.addListener(
      () => _viewModel.setEmail(_emailController.text),
    );
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
        AppPageTransitions.authSmooth<void>(
          ResetPasswordScreen(
            email: _viewModel.email,
            resetToken: _viewModel.resetToken,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final errors = _viewModel.fieldErrors;
        final loading = _viewModel.isLoading;
        final otpSent = _viewModel.otpSent;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Same violet bloom as the login screen, anchored to the
              // top-right corner and sitting behind the layout, so moving
              // from sign-in to reset reads as the same place. It is outside
              // the LayoutBuilder on purpose: the glow must not change the
              // width the breakpoints below are measured against.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.85, -0.9),
                      radius: 1.0,
                      colors: [
                        p.primary.withValues(alpha: 0.26),
                        p.primary.withValues(alpha: 0.12),
                        p.primary.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (ctx, c) {
                      final carded = c.maxWidth >= _ForgotLayout.cardFrom;
                      final wide = c.maxWidth >= _ForgotLayout.splitFrom;
                      if (wide) {
                        return Row(
                          children: [
                            Expanded(flex: 5, child: _buildArtPane()),
                            Expanded(
                              flex: 4,
                              child: _buildFormPane(
                                errors: errors,
                                loading: loading,
                                otpSent: otpSent,
                              ),
                            ),
                          ],
                        );
                      }
                      return _centeredScroll(
                        maxWidth: carded
                            ? _ForgotLayout.cardMaxWidth
                            : _ForgotLayout.formMaxWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // On tablet the avatar lives inside the card with
                            // the form, so showing it here as well would put
                            // two copies of the same mark on one screen.
                            if (!carded) ...[
                              _buildHeaderIcon(),
                              const SizedBox(height: 20),
                            ],
                            _buildHeading(otpSent: otpSent),
                            const SizedBox(height: 28),
                            if (carded)
                              _card(
                                child: _buildForm(
                                  errors: errors,
                                  loading: loading,
                                  otpSent: otpSent,
                                ),
                              )
                            else
                              _buildForm(
                                errors: errors,
                                loading: loading,
                                otpSent: otpSent,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeading({required bool otpSent}) {
    final p = context.palette;
    return Column(
      children: [
        Text(
          context.l10n.t('Forgot Password?'),
          style: TextStyle(
            color: p.textPrimary,
            fontSize: AppTypography.displaySmallSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.t(
            otpSent
                ? 'Enter the OTP sent to your email'
                : 'Enter your email to receive a verification code',
          ),
          style: TextStyle(
            color: p.textMuted,
            fontSize: AppTypography.bodySmallSize,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Brand pane for the wide layout: the forgot-password artwork filling the
  /// panel, with left and top veils for the copy, plus right and bottom veils
  /// that close the dark frame around the artwork.
  ///
  /// The lockup, headline, supporting copy and the Email → OTP → Reset list
  /// form one block, centred vertically in the pane so the text and the list
  /// share the same middle axis instead of being pinned to opposite edges.
  Widget _buildArtPane() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/forgot.png',
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
        // Shared scrim: top-left radial, then a veil on each of the four
        // edges. See [BrandArtVeil] for why the corners need both directions.
        const BrandArtVeil(),
        Positioned.fill(
          // `_centeredScroll` supplies both the horizontal and the vertical
          // centring: its `minHeight` floor equals the pane, so the block sits
          // in the middle when there is room and scrolls when there is not.
          child: _centeredScroll(
            maxWidth: double.infinity,
            padding: const EdgeInsets.all(44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/login1.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.t('Smart POS'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.titleSmallSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  context.l10n.t('Forgot your\npassword?'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.displayMediumSize,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.t(
                    'No drama — enter your email and we will send you a 6-digit code to get you back in.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: AppTypography.bodyMediumSize,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _heroHairline(),
                      _heroRow(Icons.mail_outline, 'Email'),
                      _heroHairline(),
                      _heroRow(Icons.pin_outlined, 'OTP'),
                      _heroHairline(),
                      _heroRow(Icons.lock_reset_outlined, 'Reset'),
                      _heroHairline(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Divider colour for the art-pane list. Fixed white rather than
  /// palette-driven because the list sits on the brand gradient.
  static final Color _heroDivider = Colors.white.withValues(alpha: 0.20);

  /// The fade profile shared by a row's tint and its rules, so the colour and
  /// the top and bottom lines start and end together, and neither begins hard
  /// at the left edge.
  LinearGradient _heroFade(Color color) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withValues(alpha: 0),
        color,
        color,
        color.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.10, 0.55, 1.0],
    );
  }

  /// A horizontal rule that matches the tint of the row it bounds.
  Widget _heroHairline() {
    return Container(
      height: 1,
      decoration: BoxDecoration(gradient: _heroFade(_heroDivider)),
    );
  }

  /// One row in the art-pane list: icon and label on a faint glass tint.
  Widget _heroRow(IconData icon, String key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: _heroFade(Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.t(key),
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTypography.labelMediumSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Right-hand form pane used by the wide split layout.
  ///
  /// Mirrors the login screen's split pane: the card carries the illustration
  /// and the form, and the heading lives on the brand pane rather than being
  /// repeated above the card.
  Widget _buildFormPane({
    required Map<String, String?> errors,
    required bool loading,
    required bool otpSent,
  }) {
    return _centeredScroll(
      maxWidth: _ForgotLayout.cardMaxWidth,
      padding: const EdgeInsets.all(_ForgotLayout.panePadding),
      child: _card(
        child: _buildForm(errors: errors, loading: loading, otpSent: otpSent),
        padding: _ForgotLayout.panePadding,
      ),
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

  Widget _card({
    required Widget child,
    double padding = _ForgotLayout.cardPadding,
  }) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Same anchor as the login card: the recovery artwork as a circular
          // avatar, with a key badge instead of login's lock.
          Center(
            child: BrandAvatarBadge(
              image: 'assets/forgot.png',
              semanticLabel: context.l10n.t('Reset password'),
              size: BrandAvatarBadge.standardSize,
              badgeIcon: Icons.key_rounded,
              accent: const [AppColors.teal, AppColors.tealDark],
            ),
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }

  Widget _buildForm({
    required Map<String, String?> errors,
    required bool loading,
    required bool otpSent,
  }) {
    final p = context.palette;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: RequiredLabel('Email'),
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !otpSent,
            decoration: appInputDecoration(
              context,
              icon: Icons.email_outlined,
              hint: context.l10n.t('Enter your email'),
              errorText: errors['email'],
            ),
          ),
          if (!otpSent) ...[
            const SizedBox(height: 22),
            GradientButton(
              label: context.l10n.t('Send OTP'),
              loading: loading,
              onPressed: _handleSendOtp,
            ),
          ],
          if (otpSent) ...[
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: RequiredLabel('OTP Code'),
            ),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              decoration: appInputDecoration(
                context,
                icon: Icons.pin_outlined,
                hint: context.l10n.t('Enter 6-digit OTP'),
                errorText: errors['otp'],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: loading ? null : _handleSendOtp,
              child: Text(
                context.l10n.t('Resend OTP'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: AppTypography.labelMediumSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 22),
            GradientButton(
              label: context.l10n.t('Verify OTP'),
              loading: loading,
              onPressed: _handleVerifyOtp,
            ),
          ],
          if (_viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildError(p),
            ),
          const SizedBox(height: 22),
          _buildDivider(),
          const SizedBox(height: 18),
          _buildBackToLogin(),
        ],
      ),
    );
  }

  /// Error banner matching the login screen's, so a failed step reads the same
  /// way on both screens.
  Widget _buildError(AppPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.dangerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _viewModel.errorMessage!,
        style: TextStyle(
          color: p.dangerFg,
          fontSize: AppTypography.labelMediumSize,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDivider() {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: p.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.t('OR'),
            style: TextStyle(
              color: p.textMuted,
              fontSize: AppTypography.labelMediumSize,
            ),
          ),
        ),
        Expanded(child: Divider(color: p.border)),
      ],
    );
  }

  Widget _buildHeaderIcon() {
    return BrandAvatarBadge(
      image: 'assets/forgot.png',
      semanticLabel: context.l10n.t('Reset password'),
      size: BrandAvatarBadge.standardSize,
      badgeIcon: Icons.key_rounded,
      // The artwork is violet edge to edge, so the default violet frame would
      // disappear into it. Teal is the app's secondary accent and gives the
      // avatar a visible edge without adding another brand hue.
      accent: const [AppColors.teal, AppColors.tealDark],
    );
  }

  Widget _buildBackToLogin() {
    final p = context.palette;
    // Wrap rather than Row: translated prompts run long (Myanmar is ~400dp at
    // 14px), and both halves need to be able to move onto a second line instead
    // of throwing a RenderFlex overflow.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Text(
          context.l10n.t('Remember your password?'),
          style: TextStyle(
            color: p.textMuted,
            fontSize: AppTypography.bodySmallSize,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            context.l10n.t('Back to Login'),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: AppTypography.bodySmallSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
