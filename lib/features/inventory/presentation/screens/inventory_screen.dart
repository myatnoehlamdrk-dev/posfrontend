import 'package:flutter/material.dart';
import 'package:posfrontend/features/inventory/domain/entities/inventory.dart';
import 'package:posfrontend/features/inventory/presentation/viewmodels/inventory_view_model.dart';
import 'package:posfrontend/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:posfrontend/features/category/presentation/screens/category_screen.dart';
import 'package:posfrontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final InventoryViewModel _viewModel;

  static const Color purple = Color(0xFF6D28D9);

  @override
  void initState() {
    super.initState();
    _viewModel = InventoryViewModel(
      repository: InventoryRepositoryImpl(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          navigateToDashboard(context);
        }
      },
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth >= 768;
          if (isWide) {
            return Scaffold(
              backgroundColor: p.surface,
              body: Row(
                children: [
                  SizedBox(
                    width: 240,
                    child: AppDrawer(activeItem: 'Inventory'),
                  ),
                  Expanded(child: _buildContent(isWide: true)),
                ],
              ),
            );
          }
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: p.surface,
            drawer: AppDrawer(activeItem: 'Inventory'),
            body: _buildContent(isWide: false),
          );
        },
      ),
    );
  }

  Widget _buildContent({required bool isWide}) {
    final p = context.palette;
    final options = _viewModel.options;
    return SafeArea(
      child: Column(
        children: [
          AppScreenTopBar(
            title: 'Inventory',
            showMenuButton: !isWide,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: RefreshableBody(
              onRefresh: () async {},
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _breadcrumb(),
                    const SizedBox(height: 16),
                    Text(
                      'Choose an inventory to manage your items.',
                      style: TextStyle(fontSize: 16, color: p.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    _buildOptionCards(options, isWide: isWide),
                    const SizedBox(height: 32),
                    _infoCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breadcrumb() {
    final p = context.palette;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DashboardScreen()),
          ),
          child: const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: purple,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('>', style: TextStyle(fontSize: 14, color: p.textSecondary)),
        const SizedBox(width: 8),
        Text(
          'Inventory',
          style: TextStyle(fontSize: 14, color: p.textSecondary),
        ),
      ],
    );
  }

  Widget _buildOptionCards(List<InventoryOptionEntity> options, {required bool isWide}) {
    final cards = options
        .map((o) => _optionCard(o))
        .toList();
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 24),
          Expanded(child: cards[1]),
        ],
      );
    }
    return Column(
      children: [
        cards[0],
        const SizedBox(height: 24),
        cards[1],
      ],
    );
  }

  Widget _optionCard(InventoryOptionEntity option) {
    final p = context.palette;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 430, maxHeight: 480),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: p.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: p.selectionTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder,
                color: Color(0xFF6D28D9),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              option.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              option.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: p.textSecondary),
            ),
            const Spacer(),
            _gradientButton(
              'Open',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryScreen(
                    inventoryType: option.key,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton(String label, {VoidCallback? onTap}) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [p.primary, AppColors.primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.selectionTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF6D28D9)),
              const SizedBox(width: 8),
              Text(
                "What's the difference?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bullet('Self Inventory: Only you can view and manage.'),
          const SizedBox(height: 6),
          _bullet('Public Inventory: Shared and visible to other users.'),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: TextStyle(fontSize: 14, color: p.textSecondary)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: p.textSecondary),
          ),
        ),
      ],
    );
  }
}
