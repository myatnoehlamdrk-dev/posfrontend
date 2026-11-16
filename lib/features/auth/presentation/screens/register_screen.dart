import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/features/auth/domain/usecases/register.dart';
import 'package:posfrontend/features/auth/presentation/viewmodels/register_view_model.dart';
import 'package:posfrontend/features/auth/presentation/screens/verify_account_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/required_label.dart';
import 'package:posfrontend/shared/widgets/wizard_step_indicator.dart';
import 'package:mm_nrc_kit/mm_nrc_kit.dart';

/// Layout thresholds, matching the create-shop screen so the two wizards agree
/// on what "wide" means and a user moving between them sees the same shape.
///
/// Three steps rather than two, so the widest step — user detail, with six
/// fields — is one screen rather than two. The form column is capped at the
/// login screen's width and keeps one field per row, so a desktop window shows
/// the same compact column as sign-in instead of a page-wide form.
class _RegisterLayout {
  _RegisterLayout._();

  /// Same 768 the product, inventory, sale and shop screens use.
  static const double twoPaneFrom = 768;

  /// The wizard's form column stops at the login screen's card width. Before
  /// this, the form could grow to 1040px on a desktop and the inputs read as
  /// page-wide bars; capping it means every auth screen shows the same compact
  /// column.
  static const double formMaxWidth = 460;

  static const double actionsMaxWidth = 640;
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
          builder: (_) => VerifyAccountScreen(
            email: _viewModel.email,
            // register already mailed the code -- a second send here is what
            // put two verification emails in the inbox on every sign-up.
            sendOnOpen: false,
          ),
        ),
      );
    }
  }

  /// Brand pane for the wide layout: the register artwork filling the panel,
  /// with a left-edge gradient so the headline reads on every screen size.
  Widget _buildArtPane() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/register.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.30),
                Colors.black.withValues(alpha: 0.62),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Bottom-anchored, but scrollable when the pane is short. On a
        // landscape phone this pane is ~330dp tall while the copy below is
        // ~400dp, and a bare `Positioned` would clip the lockup and the
        // headline off the top with no way to reach them.
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, c) {
              const inset = 44.0;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(inset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (c.maxHeight - inset * 2)
                        .clamp(0.0, double.infinity)
                        .toDouble(),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                        context.l10n.t('A home for\nyour shop.'),
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
                          'Create your account and open the till in minutes — sales, stock, staff and receipts in one place.',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: AppTypography.bodyMediumSize,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Tinted rows with rules that fade in from the left and out to
                      // the right. The tint and the rules share [_heroFade], so the
                      // colour never starts hard at the edge and the lines on each row's
                      // top and bottom stay exactly with it.
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _heroHairline(),
                            _heroRow(Icons.point_of_sale_outlined, 'Checkout'),
                            _heroHairline(),
                            _heroRow(Icons.inventory_2_outlined, 'Inventory'),
                            _heroHairline(),
                            _heroRow(Icons.receipt_long_outlined, 'Receipts'),
                            _heroHairline(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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

  /// The scrollable form column used by both the narrow single-column layout
  /// and the wide form pane of the split layout.
  Widget _buildFormScrollView({
    required double width,
    required bool isWide,
    required Widget form,
    required BoxConstraints constraints,
  }) {
    final height = constraints.maxHeight;
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
            maxWidth: _RegisterLayout.formMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // On the single-column layout the artwork doubles as a
              // decorative hero above the form; falls back gracefully on
              // short screens.
              if (!isWide && height > 640) ...[
                Center(
                  child: Image.asset(
                    'assets/register.png',
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              form,
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionalLabel(String text) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: p.textPrimary,
          fontSize: AppTypography.bodySmallSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _helperText(String text) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(
          color: p.textMuted,
          fontSize: AppTypography.labelSmallSize,
        ),
      ),
    );
  }

  /// A card of related fields.
  ///
  /// Login's form is a plain card of fields, and this now matches it: the
  /// wizard's step indicator already says which step is showing, so the old
  /// icon-plus-title-plus-subtitle header only added height above the fields.
  Widget _sectionCard({required List<Widget> children}) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        children: children,
      ),
    );
  }

  // ---------------------------------------------------------------- steps

  Widget _buildUserInfoStep(Map<String, String?> errors) {
    return _sectionCard(
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
              tooltip: 'Toggle password visibility',
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
  Widget _buildUserDetailStep() {
    // The NRC field shows the server's format error, so it needs the same
    // field-error map the shop step passes in.
    final errors = _viewModel.fieldErrors;
    final p = context.palette;

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
      // The standard Myanmar NRC picker (mm_nrc_kit), English labels: pick
      // the state, township, citizenship letter and 6-digit serial; it
      // composes the API string (12/MAKANA(N)123456) itself. The tile shows
      // its own "NRC Number" title, so no label is repeated above it.
      NRCField(
        language: NrcLanguage.english,
        backgroundColor: p.surfaceAlt,
        borderColor: p.border,
        borderWidth: 1,
        borderRadius: AppRadius.md,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        leadingTitleColor: p.textMuted,
        leadingTitleFontSize: AppTypography.bodySmallSize,
        trailingTitleFontSize: AppTypography.bodySmallSize,
        pickerItemColor: p.textPrimary,
        onCompleted: (value) => _viewModel.setNrc(value ?? ''),
        onChanged: (value) => _viewModel.setNrc(value ?? ''),
      ),
      if (errors['nrc'] != null) ...[
        const SizedBox(height: 6),
        Text(
          errors['nrc']!,
          style: TextStyle(
            fontSize: AppTypography.labelSmallSize,
            color: p.dangerFg,
          ),
        ),
      ],
    ];

    // One field per row: the form column is login-width now, so pairing would
    // squeeze each input to roughly 200px and undo the compact column.
    final children = [
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

    return _sectionCard(children: children);
  }

  Widget _buildShopInfoStep(Map<String, String?> errors) {
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
      RequiredLabel('Service Fee Way'),
      TextFormField(
        controller: _billingController,
        decoration: appInputDecoration(
          context,
          icon: Icons.payment_outlined,
          hint: context.l10n.t('Enter service feed way'),
          errorText: errors['billingWay'],
        ),
      ),
      _helperText('e.g. Cash, Bank Transfer, Mobile Payment, Credit'),
    ];

    // One field per row, matching the login-width form column.
    final children = [...role, const SizedBox(height: 16), ...billing];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _currentShopCard(),
        const SizedBox(height: 16),
        _sectionCard(children: children),
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
                    fontSize: AppTypography.bodyLargeSize,
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
                      fontSize: AppTypography.bodySmallSize,
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
                        fontSize: AppTypography.labelSmallSize,
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

                              return ListenableBuilder(
                                listenable: _viewModel,
                                builder: (context, _) {
                                  final errors = _viewModel.fieldErrors;

                                  final form = Form(
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
                                              1 => _buildUserDetailStep(),
                                              _ => _buildShopInfoStep(errors),
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
                                                fontSize: AppTypography
                                                    .labelMediumSize,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  );

                                  if (isWide) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: _buildArtPane(),
                                        ),
                                        Expanded(
                                          flex: 6,
                                          child: _buildFormScrollView(
                                            width: constraints.maxWidth,
                                            isWide: isWide,
                                            form: form,
                                            constraints: constraints,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return _buildFormScrollView(
                                    width: constraints.maxWidth,
                                    isWide: isWide,
                                    form: form,
                                    constraints: constraints,
                                  );
                                },
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
