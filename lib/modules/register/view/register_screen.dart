import 'package:flutter/material.dart';
import 'package:posfrontend/modules/register/repository/auth_repository_impl.dart';
import 'package:posfrontend/modules/register/viewmodel/register_view_model.dart';
import 'package:posfrontend/modules/shop/repository/shop_api_repository_impl.dart';
import 'package:posfrontend/modules/shop/repository/shop_local_repository_impl.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';

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

  static const Color primary = Color(0xFF7B2CBF);
  static const Color primaryLight = Color(0xFF9D4EDD);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color labelColor = Color(0xFF1A1A1A);
  static const Color hintColor = Color(0xFF9E9E9E);

  static const List<String> _genders = [
    'Male',
    'Female',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = RegisterViewModel(
      shopRepository: ShopLocalRepositoryImpl(),
      shopApiRepository: ShopApiRepositoryImpl(),
      imgbbRepository: ImgbbRepositoryImpl(),
      authRepository: AuthRepositoryImpl(),
    );
    _viewModel.loadShop();

    _nameController.addListener(() => _viewModel.setName(_nameController.text));
    _emailController.addListener(() => _viewModel.setEmail(_emailController.text));
    _passwordController
        .addListener(() => _viewModel.setPassword(_passwordController.text));
    _phoneController.addListener(() => _viewModel.setPhone(_phoneController.text));
    _socialController.addListener(() => _viewModel.setSocial(_socialController.text));
    _roleController.addListener(() => _viewModel.setRole(_roleController.text));
    _addressController
        .addListener(() => _viewModel.setAddress(_addressController.text));
    _nrcController.addListener(() => _viewModel.setNrc(_nrcController.text));
    _billingController
        .addListener(() => _viewModel.setBillingWay(_billingController.text));
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

  InputDecoration _inputDecoration({
    required IconData icon,
    required String hint,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      hintStyle: const TextStyle(color: hintColor, fontSize: 14),
      prefixIcon: Icon(icon, color: primary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _requiredLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: labelColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _helperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(color: hintColor, fontSize: 12),
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: primary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final errors = _viewModel.fieldErrors;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _requiredLabel('Full Name'),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              icon: Icons.person_outline,
                              hint: 'Enter full name',
                              errorText: errors['name'],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _requiredLabel('Email'),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              icon: Icons.email_outlined,
                              hint: 'Enter email address',
                              errorText: errors['email'],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _requiredLabel('Password'),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                              icon: Icons.lock_outline,
                              hint: 'Enter password',
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
                                  color: hintColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _sectionHeading('Contact Info'),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _optionalLabel('Phone'),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: _inputDecoration(
                                        icon: Icons.phone_outlined,
                                        hint: 'Phone number',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _optionalLabel('Social'),
                                    TextFormField(
                                      controller: _socialController,
                                      decoration: _inputDecoration(
                                        icon: Icons.chat_outlined,
                                        hint: 'Social (e.g. Telegram, Viber)',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _optionalLabel('User Role'),
                          TextFormField(
                            controller: _roleController,
                            decoration: _inputDecoration(
                              icon: Icons.supervisor_account_outlined,
                              hint: 'Enter user role',
                            ),
                          ),
                          _helperText(
                            'e.g. Manager, Cashier, Accountant, Staff',
                          ),
                          const SizedBox(height: 20),
                          _optionalLabel('User Address'),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              icon: Icons.location_on_outlined,
                              hint: 'Enter user address',
                            ),
                          ),
                          const SizedBox(height: 20),
                          _requiredLabel('Current Shop'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.store_outlined,
                                  color: primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _viewModel.shopName ?? 'No shop created yet',
                                    style: TextStyle(
                                      color: _viewModel.shopName != null
                                          ? labelColor
                                          : hintColor,
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
                                      color: const Color(0xFFF7F0FB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _viewModel.shopType!,
                                      style: const TextStyle(
                                        color: primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _optionalLabel('NRC No.'),
                          TextFormField(
                            controller: _nrcController,
                            decoration: _inputDecoration(
                              icon: Icons.credit_card_outlined,
                              hint: 'Enter NRC number',
                            ),
                          ),
                          const SizedBox(height: 20),
                          _requiredLabel('Billing Way'),
                          TextFormField(
                            controller: _billingController,
                            decoration: _inputDecoration(
                              icon: Icons.payment_outlined,
                              hint: 'Enter billing way',
                              errorText: errors['billingWay'],
                            ),
                          ),
                          _helperText(
                            'e.g. Cash, Bank Transfer, Mobile Payment, Credit',
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          _dobController.text =
                                              '${picked.day}/${picked.month}/${picked.year}';
                                          _viewModel.setDob(_dobController.text);
                                        }
                                      },
                                      decoration: _inputDecoration(
                                        icon: Icons.calendar_today_outlined,
                                        hint: 'Select date of birth',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _optionalLabel('Gender'),
                                    DropdownButtonFormField<String>(
                                      initialValue: _viewModel.gender,
                                      isExpanded: true,
                                      decoration: _inputDecoration(
                                        icon: Icons.wc_outlined,
                                        hint: 'Select gender',
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
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back, color: primary),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Register',
                style: TextStyle(
                  color: labelColor,
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

  Widget _buildSubmitButton() {
    final loading = _viewModel.isLoading;
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading
            ? null
            : () async {
                final success = await _viewModel.register();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Registration successful'),
                      backgroundColor: primary,
                    ),
                  );
                }
              },
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
