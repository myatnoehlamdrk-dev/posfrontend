import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/profile/repository/profile_repository_impl.dart';
import 'package:posfrontend/modules/profile/viewmodel/profile_view_model.dart';
import 'package:posfrontend/modules/shop/model/shop.dart';
import 'package:posfrontend/modules/shop/repository/shop_api_repository_impl.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';

class ProfileScreen extends StatefulWidget {
  final LoginResponse? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

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

  Shop? _shop;

  static const Color primary = Color(0xFF7B2CBF);
  static const Color primaryLight = Color(0xFF9D4EDD);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color labelColor = Color(0xFF1A1A1A);
  static const Color hintColor = Color(0xFF9E9E9E);
  static const Color cardBg = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel(repository: ProfileRepositoryImpl());
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadProfile();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final shopId = widget.user?.shopId ?? '';
    if (shopId.isEmpty) return;
    try {
      final shop = await ShopApiRepositoryImpl().getShopById(shopId);
      if (mounted) setState(() => _shop = shop);
    } catch (_) {}
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
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      final result = await ImgbbRepositoryImpl().uploadImage(
        bytes,
        fileName: xfile.name,
      );
      final url = result.url;
      _viewModel.setImageUrl(url);
      ProfileImageNotifier.instance.update(url);
      await _viewModel.saveProfile();
    }
  }

  Future<void> _save() async {
    final success = await _viewModel.saveProfile();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.successMessage),
          backgroundColor: primary,
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _obscureCurrent = true;
    _obscureNew = true;
    _obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) {
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
                          hintStyle: const TextStyle(color: hintColor),
                          prefixIcon: const Icon(Icons.lock_outline, color: primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: hintColor,
                              size: 20,
                            ),
                            onPressed: () => setDialogState(
                                () => _obscureCurrent = !_obscureCurrent),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          hintText: 'New password',
                          hintStyle: const TextStyle(color: hintColor),
                          prefixIcon: const Icon(Icons.lock_outline, color: primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: hintColor,
                              size: 20,
                            ),
                            onPressed: () => setDialogState(
                                () => _obscureNew = !_obscureNew),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Confirm new password',
                          hintStyle: const TextStyle(color: hintColor),
                          prefixIcon: const Icon(Icons.lock_outline, color: primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: hintColor,
                              size: 20,
                            ),
                            onPressed: () => setDialogState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: hintColor)),
                ),
                ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) {
                    return ElevatedButton(
                      onPressed: _viewModel.isChangingPassword
                          ? null
                          : () async {
                              final success = await _viewModel.changePassword(
                                currentPassword: _currentPasswordController.text,
                                newPassword: _newPasswordController.text,
                              );
                              if (success && ctx.mounted) {
                                Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_viewModel.successMessage),
                                      backgroundColor: primary,
                                    ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    );
                  },
                ),
              ],
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
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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
            child: loading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: SingleChildScrollView(
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
                                  controller: _statusController,
                                  label: 'Status',
                                  icon: Icons.flag_outlined,
                                  onChanged: _viewModel.setStatus,
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
                                _shopInfoRow(
                                  icon: Icons.store_outlined,
                                  label: 'Shop Name',
                                  value: _shop?.name ?? '-',
                                ),
                                const SizedBox(height: 10),
                                _shopInfoRow(
                                  icon: Icons.category_outlined,
                                  label: 'Shop Type',
                                  value: _shop?.type ?? '-',
                                ),
                                const SizedBox(height: 10),
                                _shopInfoRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Address',
                                  value: _shop?.physicalAddress ?? '-',
                                ),
                                const SizedBox(height: 10),
                                _shopInfoRow(
                                  icon: Icons.person_outline,
                                  label: 'Owner',
                                  value: _shop?.ownerInformation.name ?? '-',
                                ),
                                const SizedBox(height: 10),
                                _shopInfoRow(
                                  icon: Icons.email_outlined,
                                  label: 'Owner Email',
                                  value: _shop?.ownerInformation.email ?? '-',
                                ),
                                const SizedBox(height: 10),
                                _shopInfoRow(
                                  icon: Icons.phone_outlined,
                                  label: 'Owner Phone',
                                  value: _shop?.ownerInformation.phone ?? '-',
                                ),
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
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      _viewModel.errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                if (_viewModel.successMessage.isNotEmpty &&
                                    _viewModel.errorMessage == null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      _viewModel.successMessage,
                                      style: const TextStyle(
                                        color: Colors.green,
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
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: primary),
          ),
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
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFE9D5FF),
                  backgroundImage:
                      image.isNotEmpty ? NetworkImage(image) : null,
                  child: image.isEmpty
                      ? const Icon(Icons.person, size: 50, color: primary)
                      : null,
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
            style: const TextStyle(
              fontSize: 14,
              color: hintColor,
            ),
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
