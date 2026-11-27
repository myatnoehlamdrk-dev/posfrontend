import 'package:flutter/material.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
import 'package:posfrontend/features/auth/domain/entities/login_result.dart';
import 'package:posfrontend/features/auth/domain/usecases/withdraw_membership_request.dart';
import 'package:posfrontend/features/auth/presentation/screens/login_screen.dart';
import 'package:posfrontend/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_page_transitions.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

/// Where a sign-in lands when the credentials are right but the shop has not
/// approved the account (or has declined it).
///
/// The screen holds the [LoginViewModel] rather than a fresh one so "Try again"
/// reuses the email and password already typed on the login screen. It does
/// not save a session or touch the token store: the server issued no token for
/// a pending account.
class PendingApprovalScreen extends StatefulWidget {
  final LoginViewModel viewModel;
  final MembershipPendingException request;

  /// Called after a successful retry, with the same result the login screen
  /// would have had. The login screen owns session persistence and navigation
  /// so there is only one place that decides what a signed-in user sees.
  final Future<void> Function(LoginResult result) onSignedIn;

  const PendingApprovalScreen({
    super.key,
    required this.viewModel,
    required this.request,
    required this.onSignedIn,
  });

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  late MembershipPendingException _request;
  bool _withdrawing = false;
  String? _withdrawError;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  Future<void> _tryAgain() async {
    final result = await widget.viewModel.login();
    if (!mounted) return;

    final pending = widget.viewModel.pendingRequest;
    if (pending != null) {
      // Still waiting, or now rejected. Rebuild the copy from the server's
      // latest answer instead of the one that opened this screen.
      setState(() => _request = pending);
      return;
    }
    if (result != null) {
      await widget.onSignedIn(result);
      return;
    }
    if (widget.viewModel.hasError) {
      showErrorSnackBar(context, widget.viewModel.errorMessage!);
    }
  }

  Future<void> _withdraw() async {
    setState(() {
      _withdrawing = true;
      _withdrawError = null;
    });

    try {
      await getIt<WithdrawMembershipRequestUseCase>()(
        WithdrawMembershipRequestParams(
          email: widget.viewModel.email.trim(),
          password: widget.viewModel.password,
        ),
      );
      if (!mounted) return;
      showSuccessSnackBar(context, 'Request cancelled. You can register again.');
      Navigator.pushAndRemoveUntil(
        context,
        AppPageTransitions.fade<void>(const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _withdrawError = formatApiError(e));
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rejected = _request.rejected;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final busy = widget.viewModel.isLoading || _withdrawing;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: busy ? null : () => Navigator.pop(context),
              tooltip: context.l10n.t('Back'),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: _card(
                        p: p,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              rejected
                                  ? Icons.block_outlined
                                  : Icons.hourglass_top_outlined,
                              size: 56,
                              color: rejected ? AppColors.red : AppColors.primary,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              context.l10n.t(
                                rejected
                                    ? 'Request Not Approved'
                                    : 'Waiting for Approval',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: AppTypography.displaySmallSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              rejected
                                  ? context.l10n.t(
                                      'The shop declined your request. You can withdraw it and register again with this email.',
                                    )
                                  : context.l10n.t(
                                      'Your account is linked to this shop but is not active yet. You will be able to sign in once the owner or a manager approves it.',
                                    ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: p.textSecondary,
                                fontSize: AppTypography.bodyMediumSize,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _shopCard(p: p),
                            const SizedBox(height: 24),
                            GradientButton(
                              label: context.l10n.t('Try Again'),
                              loading: widget.viewModel.isLoading,
                              onPressed: busy ? null : _tryAgain,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: busy ? null : _withdraw,
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: Text(
                                context.l10n.t('Cancel Request'),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            if (_withdrawError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  _withdrawError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.red,
                                    fontSize: AppTypography.labelMediumSize,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _shopCard({required AppPalette p}) {
    final shopName = _request.shopName.trim();
    final ownerName = _request.ownerName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.store_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  shopName.isEmpty ? context.l10n.t('Your shop') : shopName,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: AppTypography.titleMediumSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (ownerName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${context.l10n.t('Owner')}: $ownerName',
              style: TextStyle(
                color: p.textSecondary,
                fontSize: AppTypography.bodySmallSize,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required AppPalette p, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
}
