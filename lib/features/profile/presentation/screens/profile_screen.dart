import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';
import 'package:posfrontend/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:posfrontend/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:posfrontend/features/shop/data/repositories/shop_api_repository_impl.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  bool _uploadingImage = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _socialController = TextEditingController();
  final _roleController = TextEditingController();
  final _addressController = TextEditingController();
  final _statusController = TextEditingController();
  final _nrcNoController = TextEditingController();
  final _billingWayController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _typeController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final _shopNameController = TextEditingController();
  final _shopTypeController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  static const Color primary = Color(0xFF7B2CBF);
  static const Color primaryLight = Color(0xFF9D4EDD);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color labelColor = Color(0xFF1A1A1A);
  static const Color hintColor = Color(0xFF9E9E9E);
  static const Color red = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel(
      repository: ProfileRepositoryImpl(),
      shopRepository: ShopApiRepositoryImpl(),
    );
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shopId = AuthScope.userOf(context)?.shopId ?? '';
    _viewModel.loadShop(shopId);
  }

  void _onViewModelChange() {
    final p = _viewModel.profile;
    if (p != null && mounted) {
      _nameController.text = _viewModel.name;
      _emailController.text = _viewModel.email;
      _phoneController.text = _viewModel.phone;
      _socialController.text = _viewModel.social;
      _roleController.text = _viewModel.role;
      _addressController.text = _viewModel.address;
      _statusController.text = _viewModel.status;
      _nrcNoController.text = _viewModel.nrcNo;
      _billingWayController.text = _viewModel.billingWay;
      _dobController.text = _viewModel.dateOfBirth;
      _genderController.text = _viewModel.gender;
      _typeController.text = _viewModel.type;
      if (_viewModel.imageUrl.isNotEmpty) {
        ProfileImageNotifier.instance.update(_viewModel.imageUrl);
      }
    }
    if (_viewModel.shop != null && mounted) {
      _shopNameController.text = _viewModel.shopName;
      _shopTypeController.text = _viewModel.shopType;
      _shopAddressController.text = _viewModel.shopAddress;
      _ownerNameController.text = _viewModel.ownerName;
      _ownerEmailController.text = _viewModel.ownerEmail;
      _ownerPhoneController.text = _viewModel.ownerPhone;
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _socialController.dispose();
    _roleController.dispose();
    _addressController.dispose();
    _statusController.dispose();
    _nrcNoController.dispose();
    _billingWayController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _typeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _shopNameController.dispose();
    _shopTypeController.dispose();
    _shopAddressController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_uploadingImage) return;
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    if (!mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final result = await ImgbbRepositoryImpl().uploadImage(
        bytes,
        fileName: xfile.name,
      );
      if (!mounted) return;
      _viewModel.setImageUrl(result.url);
      ProfileImageNotifier.instance.update(
        resolveMediaUrl(result.url) ?? result.url,
      );
      final success = await _viewModel.saveProfile();
      if (success && mounted) {
        showSuccessSnackBar(context, 'Profile updated successfully');
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (_viewModel.isSaving) return;
    final success = await _viewModel.saveProfile();
    if (success && mounted) {
      showSuccessSnackBar(context, 'Profile updated successfully');
    }
  }

  Future<void> _saveShop() async {
    if (_viewModel.isSavingShop) return;
    _viewModel.setShopName(_shopNameController.text);
    _viewModel.setShopType(_shopTypeController.text);
    _viewModel.setShopAddress(_shopAddressController.text);
    _viewModel.setOwnerName(_ownerNameController.text);
    _viewModel.setOwnerEmail(_ownerEmailController.text);
    _viewModel.setOwnerPhone(_ownerPhoneController.text);
    final success = await _viewModel.saveShop();
    if (success && mounted) {
      showSuccessSnackBar(context, 'Shop updated successfully');
    }
  }

  List<Widget> _buildShopFields() {
    final user = AuthScope.userOf(context);
    final isOwner = user?.isOwner ?? false;

    if (!isOwner) {
      return [
        _shopInfoRow(
          icon: Icons.store_outlined,
          label: 'Shop Name',
          value: _viewModel.shop?.name ?? '-',
        ),
        const SizedBox(height: 10),
        _shopInfoRow(
          icon: Icons.category_outlined,
          label: 'Shop Type',
          value: _viewModel.shop?.type ?? '-',
        ),
        const SizedBox(height: 10),
        _shopInfoRow(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: _viewModel.shop?.physicalAddress ?? '-',
        ),
        const SizedBox(height: 10),
        _shopInfoRow(
          icon: Icons.person_outline,
          label: 'Owner',
          value: _viewModel.shop?.ownerInformation.name ?? '-',
        ),
        const SizedBox(height: 10),
        _shopInfoRow(
          icon: Icons.email_outlined,
          label: 'Owner Email',
          value: _viewModel.shop?.ownerInformation.email ?? '-',
        ),
        const SizedBox(height: 10),
        _shopInfoRow(
          icon: Icons.phone_outlined,
          label: 'Owner Phone',
          value: _viewModel.shop?.ownerInformation.phone ?? '-',
        ),
      ];
    }

    return [
      _shopField(
        controller: _shopNameController,
        label: 'Shop Name',
        icon: Icons.store_outlined,
      ),
      const SizedBox(height: 12),
      _shopField(
        controller: _shopTypeController,
        label: 'Shop Type',
        icon: Icons.category_outlined,
      ),
      const SizedBox(height: 12),
      _shopField(
        controller: _shopAddressController,
        label: 'Address',
        icon: Icons.location_on_outlined,
      ),
      const SizedBox(height: 12),
      _shopField(
        controller: _ownerNameController,
        label: 'Owner Name',
        icon: Icons.person_outline,
      ),
      const SizedBox(height: 12),
      _shopField(
        controller: _ownerEmailController,
        label: 'Owner Email',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      _shopField(
        controller: _ownerPhoneController,
        label: 'Owner Phone',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),
      if (_viewModel.hasError)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _viewModel.errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      _gradientButton(
        label: 'Save Shop',
        icon: Icons.store_outlined,
        loading: _viewModel.isSavingShop,
        onTap: _saveShop,
      ),
    ];
  }

  Widget _shopField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDecoration(
            hint: 'Enter ${label.toLowerCase()}',
            icon: icon,
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _obscureCurrent = true;
    _obscureNew = true;
    _obscureConfirm = true;
    _viewModel.resetError();
    _viewModel.clearAllFieldErrors();

    showDialog(
      context: context,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return StatefulBuilder(
              builder: (ctx, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Change Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  content: SizedBox(
                    width: 380,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrent,
                            decoration: InputDecoration(
                              hintText: 'Current password',
                              errorText: _viewModel.getFieldError(
                                'currentPassword',
                              ),
                              hintStyle: const TextStyle(color: hintColor),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: primary,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrent
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: hintColor,
                                  size: 20,
                                ),
                                onPressed: () => setDialogState(
                                  () => _obscureCurrent = !_obscureCurrent,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            decoration: InputDecoration(
                              hintText: 'New password',
                              errorText: _viewModel.getFieldError(
                                'newPassword',
                              ),
                              hintStyle: const TextStyle(color: hintColor),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: primary,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNew
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: hintColor,
                                  size: 20,
                                ),
                                onPressed: () => setDialogState(
                                  () => _obscureNew = !_obscureNew,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              hintText: 'Confirm new password',
                              errorText: _viewModel.getFieldError(
                                'confirmPassword',
                              ),
                              hintStyle: const TextStyle(color: hintColor),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: primary,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: hintColor,
                                  size: 20,
                                ),
                                onPressed: () => setDialogState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: hintColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _viewModel.isChangingPassword
                          ? null
                          : () async {
                              final success = await _viewModel.changePassword(
                                currentPassword:
                                    _currentPasswordController.text,
                                newPassword: _newPasswordController.text,
                                confirmPassword:
                                    _confirmPasswordController.text,
                              );
                              if (success && ctx.mounted) {
                                Navigator.pop(ctx);
                                if (mounted) {
                                  showSuccessSnackBar(
                                    context,
                                    'Password changed successfully',
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: _viewModel.isChangingPassword
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Change Password'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.dateOfBirth.isNotEmpty
          ? DateTime.tryParse(_viewModel.dateOfBirth) ?? DateTime(2000)
          : DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _viewModel.setDateOfBirth(formatted);
      _dobController.text = formatted;
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    String? errorText,
    IconData? icon,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      hintStyle: const TextStyle(color: hintColor, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: primary, size: 20) : null,
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

  Future<void> _refresh() async {
    final shopId = AuthScope.userOf(context)?.shopId ?? '';
    await Future.wait([_viewModel.loadProfile(), _viewModel.loadShop(shopId)]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final loading = _viewModel.isLoading;
        final saving = _viewModel.isSaving;
        final errors = _viewModel.fieldErrors;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: loading && _viewModel.profile == null
                ? const Center(child: CircularProgressIndicator(color: primary))
                : Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: RefreshableBody(
                          onRefresh: _refresh,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProfileHeader(),
                                  const SizedBox(height: 24),
                                  _sectionTitle('Personal Information'),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline,
                                    errorText: errors['name'],
                                    onChanged: _viewModel.setName,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    errorText: errors['email'],
                                    onChanged: _viewModel.setEmail,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'Phone',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    onChanged: _viewModel.setPhone,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _socialController,
                                    label: 'Social Media',
                                    icon: Icons.link,
                                    onChanged: _viewModel.setSocial,
                                  ),
                                  const SizedBox(height: 24),
                                  _sectionTitle('Account Details'),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _typeController,
                                    label: 'Type',
                                    icon: Icons.category_outlined,
                                    onChanged: _viewModel.setType,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _roleController,
                                    label: 'Role',
                                    icon: Icons.admin_panel_settings_outlined,
                                    onChanged: _viewModel.setRole,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _nrcNoController,
                                    label: 'NRC No',
                                    icon: Icons.badge_outlined,
                                    onChanged: _viewModel.setNrcNo,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _billingWayController,
                                    label: 'Billing Way for Service',
                                    icon: Icons.receipt_long_outlined,
                                    onChanged: _viewModel.setBillingWay,
                                  ),
                                  const SizedBox(height: 24),
                                  _sectionTitle('Personal Details'),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _dobController,
                                    label: 'Date of Birth',
                                    icon: Icons.cake_outlined,
                                    readOnly: true,
                                    onTap: _pickDob,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _genderController,
                                    label: 'Gender',
                                    icon: Icons.wc_outlined,
                                    onChanged: _viewModel.setGender,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _addressController,
                                    label: 'Address',
                                    icon: Icons.location_on_outlined,
                                    maxLines: 2,
                                    onChanged: _viewModel.setAddress,
                                  ),
                                  const SizedBox(height: 24),
                                  _sectionTitle('About Shop'),
                                  const SizedBox(height: 12),
                                  ..._buildShopFields(),
                                  const SizedBox(height: 24),
                                  _gradientButton(
                                    label: 'Change Password',
                                    icon: Icons.vpn_key_outlined,
                                    loading: false,
                                    onTap: _showChangePasswordDialog,
                                  ),
                                  const SizedBox(height: 32),
                                  if (_viewModel.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        _viewModel.errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  _gradientButton(
                                    label: 'Save Profile',
                                    icon: Icons.save_outlined,
                                    loading: saving,
                                    onTap: _save,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
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

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          const CustomBackButton(),
          const Expanded(
            child: Center(
              child: Text(
                'My Profile',
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

  Widget _buildProfileHeader() {
    final image = _viewModel.imageUrl;
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _uploadingImage ? null : _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFE9D5FF),
                  backgroundImage: image.isNotEmpty
                      ? NetworkImage(image)
                      : null,
                  onBackgroundImageError: image.isNotEmpty
                      ? (e, s) {
                          _viewModel.setImageUrl('');
                          ProfileImageNotifier.instance.update('');
                        }
                      : null,
                  child: image.isEmpty
                      ? const Icon(Icons.person, size: 50, color: primary)
                      : null,
                ),
                if (_uploadingImage)
                  const Positioned.fill(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0x80000000),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _viewModel.name.isNotEmpty ? _viewModel.name : 'Your Name',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _viewModel.email.isNotEmpty ? _viewModel.email : 'your@email.com',
            style: const TextStyle(fontSize: 14, color: hintColor),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }

  Widget _shopInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? errorText,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    int maxLines = 1,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLines: maxLines,
          onChanged: onChanged,
          onTap: onTap,
          decoration: _inputDecoration(
            hint: 'Enter ${label.toLowerCase()}',
            errorText: errorText,
            icon: icon,
            suffixIcon: suffixIcon,
            readOnly: readOnly,
          ),
        ),
      ],
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required bool loading,
    required VoidCallback? onTap,
  }) {
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
        onTap: loading ? null : onTap,
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
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
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
