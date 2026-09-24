import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/screens/add_product_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/quick_add_product_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/stock_add_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';

class AddProductOptionsScreen extends StatefulWidget {
  const AddProductOptionsScreen({super.key});

  @override
  State<AddProductOptionsScreen> createState() => _AddProductOptionsScreenState();
}

class _AddProductOptionsScreenState extends State<AddProductOptionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(activeItem: 'Add Product'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTopBar(
                title: 'Add Product',
                showMenuButton: true,
                showBackButton: false,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how you want to add a product',
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              _OptionCard(
                icon: Icons.flash_on_rounded,
                iconBgColor: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFEA580C),
                title: 'Quick Add',
                subtitle: 'Add a product with minimal details — name, price, and stock only.',
                onTap: () => _navigateTo(context, 'quick'),
              ),
              const SizedBox(height: 16),
              _OptionCard(
                icon: Icons.inventory_2_outlined,
                iconBgColor: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF16A34A),
                title: 'Stock Add',
                subtitle: 'Add stock to an existing product or create with detailed inventory tracking.',
                onTap: () => _navigateTo(context, 'stock'),
              ),
              const SizedBox(height: 16),
              _OptionCard(
                icon: Icons.edit_note_rounded,
                iconBgColor: const Color(0xFFF5F0FF),
                iconColor: const Color(0xFF7C3AED),
                title: 'Normal Add',
                subtitle: 'Full product creation with all details — image, variants, categories, and supply chain.',
                onTap: () => _navigateTo(context, 'normal'),
              ),
            ],
          ),
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
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
                      style: const TextStyle(
                        color: AppColors.titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.gray,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gray,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
