// No `hide ThemeMode` any more: the feature's own enum is `AppThemeMode`, so
// there was never a collision to dodge, and hiding it only hid Flutter's.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/theme/theme_mode_notifier.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/features/auth/presentation/screens/login_screen.dart';
import 'package:posfrontend/features/settings/domain/entities/settings.dart';
import 'package:posfrontend/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:posfrontend/features/settings/presentation/screens/terms_of_service_screen.dart';
import 'package:posfrontend/features/settings/presentation/viewmodels/settings_view_model.dart';
import 'package:posfrontend/features/settings/presentation/widgets/settings_skeleton.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final SettingsViewModel _viewModel;
  bool _isLoggingOut = false;

  // Orange and red are mid-tone brand accents that read correctly on both
  // light and dark surfaces, so they stay const. The neutrals have to track
  // brightness and therefore resolve from the active theme.
  static const Color orange = Color(0xFFF97316);
  static const Color red = Color(0xFFEF4444);

  AppPalette get _p => context.palette;
  Color get titleColor => _p.textPrimary;
  Color get gray => _p.textSecondary;
  Color get border => _p.border;
  Color get sectionGray => _p.textMuted;
  Color get cardBg => _p.chipBg;

  String _userName(BuildContext context) {
    final user = AuthScope.userOf(context);
    final name = user?.fullName.trim() ?? '';
    return name.isNotEmpty ? name : 'Aung Ko Ko';
  }

  String _email(BuildContext context) => AuthScope.userOf(context)?.email ?? 'aungkoko@example.com';

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
    return Scaffold(
      key: _scaffoldKey,
      // Page fill sits one step back from the cards, so the cards stay readable
      // in dark where there is no drop shadow to separate them.
      backgroundColor: context.palette.scaffoldBg,
      drawer: const AppDrawer(activeItem: 'Setting'),
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: 'Setting',
              showMenuButton: true,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return RefreshableBody(
                    onRefresh: () => _viewModel.loadSettings(),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_viewModel.isLoading && !_viewModel.isInitialized)
                            const SettingsSkeleton()
                          else ...[
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
                            _sectionHeader('SHOP'),
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
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
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: context.palette.cardShadow,
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
                _initial(_userName(context)),
                style: TextStyle(
                  color: context.palette.surface,
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
                    _userName(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _email(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: gray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: gray, size: 24),
          ],
        ),
      ),
    );
  }

  /// "Match System" is the only permanent control. The explicit light/dark
  /// choice is a follow-up question, so it stays hidden until the user opts out
  /// of following the OS.
  Widget _buildAppearanceCard() {
    final isSystem = ThemeModeNotifier.instance.value == ThemeMode.system;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _settingsCard(
      child: Column(
        children: [
          _settingsRow(
            icon: Icons.brightness_auto_outlined,
            label: 'Match System',
            trailing: Switch(
              // No explicit thumb/track colours: the theme's switchTheme already
              // resolves them per brightness, and a hardcoded white thumb is
              // invisible on a light track.
              value: isSystem,
              onChanged: (v) => _viewModel.setSystemTheme(enabled: v),
            ),
            onTap: () => _viewModel.setSystemTheme(enabled: !isSystem),
          ),
          if (!isSystem) ...[
            Divider(height: 1, color: border),
            _settingsRow(
              icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              label: isDark ? 'Dark Mode' : 'Light Mode',
              trailing: Switch(
                value: isDark,
                onChanged: (_) => _viewModel.toggleTheme(),
              ),
              onTap: _viewModel.toggleTheme,
            ),
          ],
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
              style: TextStyle(fontSize: 14, color: gray),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: gray, size: 24),
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
              style: TextStyle(fontSize: 14, color: gray),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: gray, size: 24),
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
                Icon(Icons.image_outlined, color: titleColor, size: 22),
                const SizedBox(width: 14),
                Expanded(
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
                          errorBuilder: (context, error, stackTrace) =>
                              _imagePlaceholder(),
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
            trailing: Icon(Icons.chevron_right, color: gray, size: 24),
            onTap: _showFeedbackForm,
          ),
          Divider(height: 1, color: border),
          _settingsRow(
            icon: Icons.star_outline,
            label: 'Rate App',
            trailing: Icon(Icons.chevron_right, color: gray, size: 24),
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
            trailing: Icon(Icons.chevron_right, color: gray, size: 24),
            onTap: _showAboutDialog,
          ),
          Divider(height: 1, color: border),
          _settingsRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            trailing: Icon(Icons.chevron_right, color: gray, size: 24),
            onTap: _showPrivacyPolicy,
          ),
          Divider(height: 1, color: border),
          _settingsRow(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            trailing: Icon(Icons.chevron_right, color: gray, size: 24),
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
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: red.withValues(alpha: 0.3)),
          ),
          child: Text(
            'Logout',
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
        // Theme-aware: a hardcoded white card stayed white in dark mode while
        // the label colours came from the palette, leaving white text on white.
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: context.palette.cardShadow,
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
                style: TextStyle(
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
              Text(
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
                      ? Icon(Icons.check, color: orange)
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
                        color: context.palette.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Shop Type',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: Icon(Icons.close, color: gray),
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
              title: Text(
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
                      Text(
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
                          hintStyle: TextStyle(color: gray),
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
                  child: Text('Cancel', style: TextStyle(color: gray)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    showSuccessMessage(context, 'Feedback submitted!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _rateApp() {
    showSuccessMessage(context, 'Redirecting to app rating...');
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'About',
            style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _aboutRow('App Name', 'Inventory'),
              const SizedBox(height: 8),
              _aboutRow('Version', _viewModel.settings.appVersion),
              const SizedBox(height: 8),
              _aboutRow('Developer', 'MDRK Mobile Team'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: TextStyle(color: orange)),
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
        Text(label, style: TextStyle(color: gray, fontSize: 14)),
        Text(value, style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  void _showTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
              content: Text('Are you sure you want to logout?', style: TextStyle(color: gray)),
              actions: [
                TextButton(
                  onPressed: _isLoggingOut ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: gray)),
                ),
                ElevatedButton(
                  onPressed: _isLoggingOut
                      ? null
                      : () async {
                          setDialogState(() => _isLoggingOut = true);
                          try {
                            final dio = ApiClient.create();
                            await dio.post('/api/auth/logout');
                          } catch (_) {
                            // Logout API failure is non-critical; proceed with local cleanup
                          }
                          await TokenStorage.clearToken();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoggingOut
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: context.palette.surface,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Logout'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
