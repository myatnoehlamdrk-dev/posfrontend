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

class _RegisterLayout {
  /// Wider than login's 440 on purpose. This form has paired fields — date of
  /// birth beside gender, phone beside social — and below roughly 700px those
  /// pairs stop being side by side and start wrapping into a tall thin stack.
  static const double formMaxWidth = 720;
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

  @override
  void initState() {
    super.initState();
    _viewModel = RegisterViewModel(
      registerUseCase: getIt<RegisterUseCase>(),
      shopRepository: getIt(),
      shopApiRepository: getIt(),
      imgbbRepository: getIt(),
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
  /// Two of these carry the whole form: Owner Info and Shop Info. It used to be
  /// three tiles — Personal Info, Contact Info, Shop Info — but the first two
  /// were both describing the same person, so splitting them made the form read
  /// taller and more fragmented than the work actually is.
  ///
  /// The icon and the one-line subtitle do the grouping work that a third
  /// heading used to: the title says which card you are in, the subtitle says
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
                child: Icon(icon, size: 20, color: p.primary),
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

  /// Scrolls when the content is taller than the window, centres when it is
  /// not, and caps the width either way. Without the cap a desktop window
  /// stretches these cards across 1900px and the paired fields — date of birth
  /// next to gender, phone next to social — drift a hand's width apart.
  Widget _centeredScroll({required Widget child, required double maxWidth}) {
    return LayoutBuilder(
      builder: (ctx, c) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: c.maxHeight - 52,
            maxWidth: maxWidth,
          ),
          child: child,
        ),
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
        return Scaffold(
          backgroundColor: p.scaffoldBg,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _centeredScroll(
                    maxWidth: _RegisterLayout.formMaxWidth,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionCard(
                            icon: Icons.person_outline,
                            title: 'Owner Info',
                            subtitle: 'The person who owns this shop',
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
                                      color: p.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
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
                                            hint: context.l10n.t(
                                              'Select date of birth',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _optionalLabel('Gender'),
                                        DropdownButtonFormField<String>(
                                          initialValue: _viewModel.gender,
                                          isExpanded: true,
                                          decoration: appInputDecoration(
                                            context,
                                            icon: Icons.wc_outlined,
                                            hint: context.l10n.t(
                                              'Select gender',
                                            ),
                                          ),
                                          items: _genders
                                              .map(
                                                (g) => DropdownMenuItem(
                                                  value: g,
                                                  child: Text(g),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) =>
                                              _viewModel.setGender(value),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _optionalLabel('Phone'),
                                        TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          decoration: appInputDecoration(
                                            context,
                                            icon: Icons.phone_outlined,
                                            hint: context.l10n.t(
                                              'Phone number',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _optionalLabel('Social'),
                                        TextFormField(
                                          controller: _socialController,
                                          decoration: appInputDecoration(
                                            context,
                                            icon: Icons.chat_outlined,
                                            hint: context.l10n.t(
                                              'Social (e.g. Telegram, Viber)',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
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
                              const SizedBox(height: 16),
                              _optionalLabel('NRC No.'),
                              TextFormField(
                                controller: _nrcController,
                                decoration: appInputDecoration(
                                  context,
                                  icon: Icons.credit_card_outlined,
                                  hint: context.l10n.t('Enter NRC number'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _sectionCard(
                            icon: Icons.store_outlined,
                            title: 'Shop Info',
                            subtitle: 'How this shop operates and is billed',
                            children: [
                              _optionalLabel('User Role'),
                              TextFormField(
                                controller: _roleController,
                                decoration: appInputDecoration(
                                  context,
                                  icon: Icons.supervisor_account_outlined,
                                  hint: context.l10n.t('Enter user role'),
                                ),
                              ),
                              _helperText(
                                'e.g. Manager, Cashier, Accountant, Staff',
                              ),
                              const SizedBox(height: 16),
                              RequiredLabel('Current Shop'),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: p.surface,
                                  border: Border.all(color: p.border),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.store_outlined,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _viewModel.shopName ??
                                            'No shop created yet',
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _viewModel.shopType!,
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
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
                              _helperText(
                                'e.g. Cash, Bank Transfer, Mobile Payment, Credit',
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          GradientButton(
                            label: context.l10n.t('Register'),
                            icon: Icons.save_outlined,
                            loading: _viewModel.isLoading,
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final success = await _viewModel.register();
                              if (success && mounted) {
                                navigator.pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => VerifyAccountScreen(
                                      email: _viewModel.email,
                                    ),
                                  ),
                                );
                              }
                            },
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
                          const SizedBox(height: 12),
                        ],
                      ),
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

  Widget _buildHeader() {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border, width: 1)),
      ),
      child: Row(
        children: [
          const CustomBackButton(),
          Expanded(
            child: Center(
              child: Text(
                context.l10n.t('Register'),
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 18,
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
}
