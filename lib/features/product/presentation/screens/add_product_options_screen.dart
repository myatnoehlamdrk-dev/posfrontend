import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/product/presentation/screens/add_product_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/quick_add_product_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/stock_add_screen.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';

class AddProductOptionsScreen extends StatefulWidget {
  const AddProductOptionsScreen({super.key});

  @override
  State<AddProductOptionsScreen> createState() =>
      _AddProductOptionsScreenState();
}

class _AddProductOptionsScreenState extends State<AddProductOptionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: p.scaffoldBg,
      drawer: const AppDrawer(active: DrawerDestination.addProduct),
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t('Add Product'),
              showMenuButton: true,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.t('Choose how you want to add a product'),
                      style: TextStyle(color: p.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    _OptionCard(
                      icon: Icons.flash_on_rounded,
                      iconBgColor: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: context.l10n.t('Quick Add'),
                      subtitle: context.l10n.t(
                        'Add a product with minimal details — name, price, and stock only.',
                      ),
                      onTap: () => _navigateTo(context, 'quick'),
                    ),
                    const SizedBox(height: 16),
                    _OptionCard(
                      icon: Icons.inventory_2_outlined,
                      iconBgColor: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      title: context.l10n.t('Stock Add'),
                      subtitle: context.l10n.t(
                        'Add stock to an existing product or create with detailed inventory tracking.',
                      ),
                      onTap: () => _navigateTo(context, 'stock'),
                    ),
                    const SizedBox(height: 16),
                    _OptionCard(
                      icon: Icons.edit_note_rounded,
                      iconBgColor: p.selectionTint,
                      iconColor: const Color(0xFF7C3AED),
                      title: context.l10n.t('Normal Add'),
                      subtitle: context.l10n.t(
                        'Full product creation with all details — image, variants, categories, and supply chain.',
                      ),
                      onTap: () => _navigateTo(context, 'normal'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String type) {
    final Widget screen = switch (type) {
      'quick' => const QuickAddProductScreen(),
      'stock' => const StockAddScreen(),
      _ => const AddProductScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: p.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
