import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/features/auth/domain/usecases/register.dart';
import 'package:posfrontend/features/auth/presentation/viewmodels/register_view_model.dart';
import 'package:posfrontend/features/auth/presentation/screens/verify_account_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/required_label.dart';
import 'package:posfrontend/shared/widgets/wizard_step_indicator.dart';

/// Layout thresholds, matching the create-shop screen so the two wizards agree
/// on what "wide" means and a user moving between them sees the same shape.
///
/// Three steps rather than two, so the widest step — user detail, with six
/// fields — is one screen rather than two. Past [twoPaneFrom] the detail step
/// pairs its fields into rows instead of stacking all six, which is what stops
/// it turning into a column you have to scroll three times on a tablet.
class _RegisterLayout {
  _RegisterLayout._();

  /// Same 768 the product, inventory, sale and shop screens use.
  static const double twoPaneFrom = 768;

  /// Wider than the shop wizard's 960 because the detail step puts two fields
  /// side by side, and below roughly that they stop being wide enough to read.
  static const double contentMaxWidth = 1040;

  static const double actionsMaxWidth = 640;
  static const double paneGap = 16;
  static const double gutter = 20;
  static const double wideGutter = 32;

  static double gutterFor(double width) =>
      width >= twoPaneFrom ? wideGutter : gutter;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _socialController = TextEditingController();
  final _roleController = TextEditingController();
  final _addressController = TextEditingController();
  final _nrcController = TextEditingController();
  final _billingController = TextEditingController();
  final _dobController = TextEditingController();

  late final RegisterViewModel _viewModel;
  bool _obscurePassword = true;

  static const List<String> _genders = ['Male', 'Female', 'Other'];

  /// Which of the three wizard steps is showing.
  int _step = 0;

  static const int _stepCount = 3;

  bool get _isFirstStep => _step == 0;
  bool get _isLastStep => _step == _stepCount - 1;

  @override
  void initState() {
    super.initState();
    _viewModel = RegisterViewModel(
      registerUseCase: getIt<RegisterUseCase>(),
      shopRepository: getIt(),
    );
    _viewModel.loadShop();

    _nameController.addListener(() => _viewModel.setName(_nameController.text));
    _emailController.addListener(
      () => _viewModel.setEmail(_emailController.text),
    );
    _passwordController.addListener(
      () => _viewModel.setPassword(_passwordController.text),
    );
    _phoneController.addListener(
      () => _viewModel.setPhone(_phoneController.text),
    );
    _socialController.addListener(
      () => _viewModel.setSocial(_socialController.text),
    );
    _roleController.addListener(() => _viewModel.setRole(_roleController.text));
    _addressController.addListener(
      () => _viewModel.setAddress(_addressController.text),
    );
    _nrcController.addListener(() => _viewModel.setNrc(_nrcController.text));
    _billingController.addListener(
      () => _viewModel.setBillingWay(_billingController.text),
    );
    _dobController.addListener(() => _viewModel.setDob(_dobController.text));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _socialController.dispose();
    _roleController.dispose();
    _addressController.dispose();
    _nrcController.dispose();
    _billingController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  /// The only way back. Wired to the header's back button *and* to the Android
  /// system back gesture via [PopScope], so the two can never disagree about
  /// where back goes — which is the usual failure when a wizard has its own
  /// back button on some routes and not others.
  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_isFirstStep) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
  }

  /// Gates each advance on the step being left, so the user is told what is
  /// missing before the page changes rather than after.
  void _goToNextStep() {
    final ok = switch (_step) {
      0 => _viewModel.validateUserInfoStep(),
      1 => _viewModel.validateDetailStep(),
      _ => _viewModel.validateShopStep(),
    };
    if (!ok) return;
    FocusScope.of(context).unfocus();
    setState(() => _step++);
  }

  Future<void> _onRegister() async {
    final navigator = Navigator.of(context);
    final success = await _viewModel.register();
    if (success && mounted) {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyAccountScreen(email: _viewModel.email),
        ),
      );
    }
  }

  Widget _optionalLabel(String text) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: p.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _helperText(String text) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: TextStyle(color: p.textMuted, fontSize: 12)),
    );
  }

  /// A titled card of related fields.
  ///
  /// The icon and the one-line subtitle do the grouping work that a third
  /// heading used to: the title says which step you are in, the subtitle says
  /// what belongs in it, and the fields below need no explanation of their own.
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: p.accentText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.t(title),
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.t(subtitle),
                      style: TextStyle(color: p.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- steps

  Widget _buildUserInfoStep(Map<String, String?> errors) {
    return _sectionCard(
      icon: Icons.person_outline,
      title: 'User Info',
      subtitle: 'The account you will sign in with',
      children: [
        RequiredLabel('Full Name'),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: appInputDecoration(
            context,
            icon: Icons.person_outline,
            hint: context.l10n.t('Enter full name'),
            errorText: errors['name'],
          ),
        ),
        const SizedBox(height: 16),
        RequiredLabel('Email'),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: appInputDecoration(
            context,
            icon: Icons.email_outlined,
            hint: context.l10n.t('Enter email address'),
            errorText: errors['email'],
          ),
        ),
        const SizedBox(height: 16),
        RequiredLabel('Password'),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: appInputDecoration(
            context,
            icon: Icons.lock_outline,
            hint: context.l10n.t('Enter password'),
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
                color: context.palette.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The widest step, so the one that most needs pairing.
  ///
  /// Date of birth sits beside gender and phone beside social. Both pairs are
  /// genuinely side by side in meaning — one is a date, one is a category; one
  /// is a number, one is a handle — so pairing them reads as grouping rather
  /// than as saving space.
  Widget _buildUserDetailStep({required bool isWide}) {
    final dob = [
      _optionalLabel('Date of Birth'),
      TextFormField(
        controller: _dobController,
        readOnly: true,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            final formatted =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            _dobController.text = formatted;
            _viewModel.setDob(formatted);
          }
        },
        decoration: appInputDecoration(
          context,
          icon: Icons.calendar_today_outlined,
          hint: context.l10n.t('Select date of birth'),
        ),
      ),
    ];

    final gender = [
      _optionalLabel('Gender'),
      DropdownButtonFormField<String>(
        initialValue: _viewModel.gender,
        isExpanded: true,
        decoration: appInputDecoration(
          context,
          icon: Icons.wc_outlined,
          hint: context.l10n.t('Select gender'),
        ),
        items: _genders
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (value) => _viewModel.setGender(value),
      ),
    ];

    final phone = [
      _optionalLabel('Phone'),
      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        decoration: appInputDecoration(
          context,
          icon: Icons.phone_outlined,
          hint: context.l10n.t('Phone number'),
        ),
      ),
    ];

    final social = [
      _optionalLabel('Social'),
      TextFormField(
        controller: _socialController,
        textInputAction: TextInputAction.next,
        decoration: appInputDecoration(
          context,
          icon: Icons.chat_outlined,
          hint: context.l10n.t('Social (e.g. Telegram, Viber)'),
        ),
      ),
    ];

    final address = [
      _optionalLabel('User Address'),
      TextFormField(
        controller: _addressController,
        maxLines: 3,
        decoration: appInputDecoration(
          context,
          icon: Icons.location_on_outlined,
          hint: context.l10n.t('Enter user address'),
        ),
      ),
    ];

    final nrc = [
      _optionalLabel('NRC No.'),
      TextFormField(
        controller: _nrcController,
        decoration: appInputDecoration(
          context,
          icon: Icons.credit_card_outlined,
          hint: context.l10n.t('Enter NRC number'),
        ),
      ),
    ];

    final children = isWide
        ? [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: dob)),
                const SizedBox(width: _RegisterLayout.paneGap),
                Expanded(child: Column(children: gender)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: phone)),
                const SizedBox(width: _RegisterLayout.paneGap),
                Expanded(child: Column(children: social)),
              ],
            ),
            const SizedBox(height: 16),
            ...address,
            const SizedBox(height: 16),
            ...nrc,
          ]
        : [
            ...dob,
            const SizedBox(height: 16),
            ...gender,
            const SizedBox(height: 16),
            ...phone,
            const SizedBox(height: 16),
            ...social,
            const SizedBox(height: 16),
            ...address,
            const SizedBox(height: 16),
            ...nrc,
          ];

    return _sectionCard(
      icon: Icons.badge_outlined,
      title: 'User Detail',
      subtitle: 'Optional details about this account holder',
      children: children,
    );
  }

  Widget _buildShopInfoStep(
    Map<String, String?> errors, {
    required bool isWide,
  }) {
    final role = [
      _optionalLabel('User Role'),
      TextFormField(
        controller: _roleController,
        textInputAction: TextInputAction.next,
        decoration: appInputDecoration(
          context,
          icon: Icons.supervisor_account_outlined,
          hint: context.l10n.t('Enter user role'),
          errorText: errors['role'],
        ),
      ),
      _helperText('e.g. Manager, Cashier, Accountant, Staff'),
    ];

    final billing = [
      RequiredLabel('Billing Way'),
      TextFormField(
        controller: _billingController,
        decoration: appInputDecoration(
          context,
          icon: Icons.payment_outlined,
          hint: context.l10n.t('Enter billing way'),
          errorText: errors['billingWay'],
        ),
      ),
      _helperText('e.g. Cash, Bank Transfer, Mobile Payment, Credit'),
    ];

    final children = isWide
        ? [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: role)),
                const SizedBox(width: _RegisterLayout.paneGap),
                Expanded(child: Column(children: billing)),
              ],
            ),
          ]
        : [...role, const SizedBox(height: 16), ...billing];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _currentShopCard(),
        const SizedBox(height: 16),
        _sectionCard(
          icon: Icons.store_outlined,
          title: 'Shop Info',
          subtitle: 'How this shop operates and is billed',
          children: children,
        ),
      ],
    );
  }

  /// Read-only summary of the shop created on the previous screen. Present so
  /// the account is visibly being attached to a real shop rather than a name
  /// the user typed two screens ago and cannot now check.
  Widget _currentShopCard() {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.store_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.t('Current Shop'),
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.store_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _viewModel.shopName ?? 'No shop created yet',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _viewModel.shopName != null
                          ? p.textPrimary
                          : p.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_viewModel.shopType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: p.selectionTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _viewModel.shopType!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- navigation

  /// Three numbered pills joined by rules that fill in as the wizard advances.
  ///
  /// Delegated to the shared indicator so this and the shop wizard cannot drift
  /// apart in colour or in when they drop the labels.
  Widget _buildStepIndicator() {
    return WizardStepIndicator(
      labels: const ['User Info', 'User Detail', 'Shop Info'],
      currentIndex: _step,
    );
  }

  /// Next on steps one and two, Register on the last. No back button: back is
  /// the header button, which is also what the system gesture calls, and having
  /// a second one at the bottom invites the two disagreeing.
  Widget _buildActions() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _RegisterLayout.actionsMaxWidth,
        ),
        child: _isLastStep
            ? GradientButton(
                label: context.l10n.t('Register'),
                icon: Icons.save_outlined,
                loading: _viewModel.isLoading,
                onPressed: _onRegister,
              )
            : GradientButton(
                label: context.l10n.t('Next'),
                icon: Icons.arrow_forward,
                onPressed: _goToNextStep,
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final p = context.palette;
    final wide =
        MediaQuery.of(context).size.width >= _RegisterLayout.twoPaneFrom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border, width: 1)),
      ),
      child: Row(
        children: [
          CustomBackButton(onTap: _goBack),
          Expanded(
            child: Center(
              child: Text(
                context.l10n.t('Register'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: wide ? 20 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final errors = _viewModel.fieldErrors;
        return PopScope(
          // Past the first step the system gesture steps back instead of
          // leaving the form, so a half-filled registration is never lost to a
          // stray back swipe.
          canPop: _isFirstStep,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _goBack();
          },
          child: Scaffold(
            // Painted behind the scroll view so the bottom of the page, past the
            // last field and under the action button, is the same colour on every
            // step and the same colour as the create-shop screen behind it.
            backgroundColor: p.scaffoldBg,
            body: Stack(
              children: [
                // Bloom anchored to the middle of the right edge here rather
                // than the top-right used on sign-in and reset: the light sits
                // alongside the two-pane form instead of behind a corner, so it
                // shows on both the single-column and two-pane layouts.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.85, 0),
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
                // `Positioned.fill` keeps the column's constraints tight: a
                // plain Stack child is laid out loosely, which would give the
                // Expanded scroll view an unbounded height.
                Positioned.fill(
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final isWide =
                                  width >= _RegisterLayout.twoPaneFrom;
                              return SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  _RegisterLayout.gutterFor(width),
                                  20,
                                  _RegisterLayout.gutterFor(width),
                                  32,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: _RegisterLayout.contentMaxWidth,
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildStepIndicator(),
                                          const SizedBox(height: 20),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            child: KeyedSubtree(
                                              key: ValueKey(_step),
                                              child: switch (_step) {
                                                0 => _buildUserInfoStep(errors),
                                                1 => _buildUserDetailStep(
                                                  isWide: isWide,
                                                ),
                                                _ => _buildShopInfoStep(
                                                  errors,
                                                  isWide: isWide,
                                                ),
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 28),
                                          _buildActions(),
                                          if (_viewModel.errorMessage != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              child: Text(
                                                _viewModel.errorMessage!,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 12),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
