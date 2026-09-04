import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart' hide ThemeMode;
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/login/view/login_screen.dart';
import 'package:posfrontend/modules/settings/model/settings_models.dart';
import 'package:posfrontend/modules/settings/viewmodel/settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  final LoginResponse? user;

  const SettingsScreen({super.key, this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsViewModel _viewModel;

  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color sectionGray = Color(0xFF9CA3AF);
  static const Color orange = Color(0xFFF97316);
  static const Color cardBg = Color(0xFFF3F4F6);
  static const Color red = Color(0xFFEF4444);

  String get _userName =>
      widget.user != null && widget.user!.fullName.trim().isNotEmpty
          ? widget.user!.fullName
          : 'Aung Ko Ko';

  String get _email => widget.user?.email ?? 'aungkoko@example.com';

  String _initial(String name) {
    if (name.trim().isEmpty) return 'A';
    return name.trim()[0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel();
    _viewModel.loadSettings();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: _viewModel.isLoading && !_viewModel.isInitialized
                ? const Center(child: CircularProgressIndicator(color: orange))
                : Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _viewModel.loadSettings(),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                const Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildProfileCard(),
                                const SizedBox(height: 28),
                                _sectionHeader('APPEARANCE'),
                                const SizedBox(height: 10),
                                _buildAppearanceCard(),
                                const SizedBox(height: 28),
                                _sectionHeader('REGIONAL'),
                                const SizedBox(height: 10),
                                _buildRegionalCard(),
                                const SizedBox(height: 28),
                                _sectionHeader('BUSINESS'),
                                const SizedBox(height: 10),
                                _buildShopImageCard(),
                                const SizedBox(height: 12),
                                _buildBusinessCard(),
                                const SizedBox(height: 28),
                                _sectionHeader('SUPPORT'),
                                const SizedBox(height: 10),
                                _buildSupportCard(),
                                const SizedBox(height: 28),
                                _sectionHeader('ABOUT'),
                                const SizedBox(height: 10),
                                _buildAboutCard(),
                                const SizedBox(height: 32),
                                _buildSignOutButton(),
                                const SizedBox(height: 32),
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
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: titleColor),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Settings',
                style: TextStyle(
                  color: titleColor,
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

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: sectionGray,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: orange,
              child: Text(
                _initial(_userName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: gray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: gray, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard() {
    return _settingsCard(
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_outlined, color: titleColor, size: 22),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Light Mode',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
          ),
          Switch(
            value: _viewModel.themeMode == ThemeMode.dark,
            onChanged: (_) => _viewModel.toggleTheme(),
            activeThumbColor: Colors.white,
            activeTrackColor: orange,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: gray,
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalCard() {
    return _settingsCard(
      child: _settingsRow(
        icon: Icons.language,
        label: 'Language',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _viewModel.language,
              style: const TextStyle(fontSize: 14, color: gray),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: gray, size: 24),
          ],
        ),
        onTap: _showLanguageSheet,
      ),
    );
  }

  Widget _buildBusinessCard() {
    return _settingsCard(
      child: _settingsRow(
        icon: Icons.business_outlined,
        label: 'Shop Type',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _viewModel.shopTypeLabel(_viewModel.shopType),
              style: const TextStyle(fontSize: 14, color: gray),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: gray, size: 24),
          ],
        ),
        onTap: _showShopTypeModal,
      ),
    );
  }

  Widget _buildShopImageCard() {
    final shopImage = _viewModel.shopImage;
    final hasImage = shopImage.isNotEmpty;

    return _settingsCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image_outlined, color: titleColor, size: 22),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Shop Image',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                ),
                if (_viewModel.isUploadingImage)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: orange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _viewModel.isUploadingImage ? null : _pickShopImage,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          shopImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        ),
                      )
                    : _imagePlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: gray, size: 32),
          const SizedBox(height: 8),
          Text(
            'Tap to change shop image',
            style: TextStyle(fontSize: 13, color: gray),
          ),
        ],
      ),
    );
  }

  Future<void> _pickShopImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      _viewModel.updateShopImage(bytes, fileName: xfile.name);
    }
  }

  Widget _buildSupportCard() {
    return _settingsCard(
      child: Column(
        children: [
          _settingsRow(
            icon: Icons.feedback_outlined,
            label: 'Feedback',
            trailing: const Icon(Icons.chevron_right, color: gray, size: 24),
            onTap: _showFeedbackForm,
          ),
          const Divider(height: 1, color: border),
          _settingsRow(
            icon: Icons.star_outline,
            label: 'Rate App',
            trailing: const Icon(Icons.chevron_right, color: gray, size: 24),
            onTap: _rateApp,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return _settingsCard(
      child: Column(
        children: [
          _settingsRow(
            icon: Icons.info_outline,
            label: 'About',
            trailing: const Icon(Icons.chevron_right, color: gray, size: 24),
            onTap: _showAboutDialog,
          ),
          const Divider(height: 1, color: border),
          _settingsRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            trailing: const Icon(Icons.chevron_right, color: gray, size: 24),
            onTap: _showPrivacyPolicy,
          ),
          const Divider(height: 1, color: border),
          _settingsRow(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            trailing: const Icon(Icons.chevron_right, color: gray, size: 24),
            onTap: _showTermsOfService,
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Center(
      child: GestureDetector(
        onTap: _signOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: red.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'Sign Out',
            style: TextStyle(
              color: red,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String label,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: titleColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final languages = ['Myanmar', 'English', 'Thai', 'Japanese', 'Korean'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final selected = lang == _viewModel.language;
                return ListTile(
                  title: Text(
                    lang,
                    style: TextStyle(
                      color: selected ? orange : titleColor,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check, color: orange)
                      : null,
                  onTap: () {
                    _viewModel.setLanguage(lang);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showShopTypeModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 340,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Shop Type',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: const Icon(Icons.close, color: gray),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.0,
                            physics: const NeverScrollableScrollPhysics(),
                            children: ShopType.values.map((type) {
                              final selected = type == _viewModel.shopType;
                              return _shopTypeCard(
                                type: type,
                                selected: selected,
                                onTap: () {
                                  _viewModel.setShopType(type);
                                  setDialogState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _shopTypeCard({
    required ShopType type,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? orange : cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _shopTypeIcon(type),
              size: 36,
              color: selected ? Colors.white : gray,
            ),
            const SizedBox(height: 8),
            Text(
              _viewModel.shopTypeLabel(type),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _shopTypeIcon(ShopType type) {
    switch (type) {
      case ShopType.shop:
        return Icons.store_outlined;
      case ShopType.service:
        return Icons.home_repair_service_outlined;
      case ShopType.restaurant:
        return Icons.restaurant_outlined;
      case ShopType.store:
        return Icons.warehouse_outlined;
    }
  }

  void _showFeedbackForm() {
    final feedbackController = TextEditingController();
    String feedbackType = 'Comment';

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
                'Feedback',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: gray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['Comment', 'Suggestion', 'Bug Report'].map((t) {
                          final isActive = t == feedbackType;
                          return ChoiceChip(
                            label: Text(t),
                            selected: isActive,
                            selectedColor: orange,
                            labelStyle: TextStyle(
                              color: isActive ? Colors.white : titleColor,
                              fontWeight: FontWeight.w500,
                            ),
                            onSelected: (_) {
                              setDialogState(() => feedbackType = t);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: feedbackController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Write your feedback...',
                          hintStyle: const TextStyle(color: gray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: orange, width: 1.5),
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
                  child: const Text('Cancel', style: TextStyle(color: gray)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback submitted!'),
                        backgroundColor: orange,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to app rating...'),
        backgroundColor: orange,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'About',
            style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _aboutRow('App Name', 'POS Frontend'),
              const SizedBox(height: 8),
              _aboutRow('Version', _viewModel.settings.appVersion),
              const SizedBox(height: 8),
              _aboutRow('Developer', 'POS Team'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: orange)),
            ),
          ],
        );
      },
    );
  }

  Widget _aboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: gray, fontSize: 14)),
        Text(value, style: const TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
          content: const SingleChildScrollView(
            child: Text(
              'This application collects minimal data necessary for providing point-of-sale services. '
              'We do not share personal information with third parties. '
              'Your data is stored securely and only used to enhance your experience.',
              style: TextStyle(color: gray, fontSize: 14, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: orange)),
            ),
          ],
        );
      },
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
          content: const SingleChildScrollView(
            child: Text(
              'By using this application, you agree to comply with and be bound by these Terms of Service. '
              'The application is provided as-is for business management purposes. '
              'We reserve the right to modify these terms at any time.',
              style: TextStyle(color: gray, fontSize: 14, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: orange)),
            ),
          ],
        );
      },
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
          content: const Text('Are you sure you want to sign out?', style: TextStyle(color: gray)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: gray)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
