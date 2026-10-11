import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/customer/presentation/viewmodels/customer_view_model.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'overview_tab.dart';
import 'customers_tab.dart';
import 'trends_tab.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen>
    with SingleTickerProviderStateMixin {
  late final CustomerViewModel _viewModel;
  late final TabController _tabController;


  @override
  void initState() {
    super.initState();
    _viewModel = CustomerViewModel();
    _tabController = TabController(length: 3, vsync: this);
    _viewModel.loadAnalytics();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _buildContent(isWide: isWide);

        if (isWide) {
          return Scaffold(backgroundColor: p.surface, body: body);
        }

        return Scaffold(backgroundColor: p.surface, body: body);
      },
    );
  }

  Widget _buildContent({required bool isWide}) {
    final p = context.palette;
    return SafeArea(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.analytics == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandPurpleDark),
            );
          }
          if (_viewModel.hasError && _viewModel.analytics == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _viewModel.errorMessage ?? 'Failed to load',
                    style: TextStyle(color: p.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _viewModel.loadAnalytics(),
                    child: Text(context.l10n.t('Retry')),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              AppScreenTopBar(
                title: context.l10n.t('Customer Data'),
                showBackButton: true,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: p.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: p.textSecondary,
                  indicator: BoxDecoration(
                    color: AppColors.brandPurpleDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Customers'),
                    Tab(text: 'Trends'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _viewModel.analytics != null
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          OverviewTab(analytics: _viewModel.analytics!),
                          CustomersTab(analytics: _viewModel.analytics!),
                          TrendsTab(analytics: _viewModel.analytics!),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}
