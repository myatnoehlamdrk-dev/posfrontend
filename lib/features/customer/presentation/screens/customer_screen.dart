import 'package:flutter/material.dart';
import 'package:posfrontend/features/customer/presentation/viewmodels/customer_view_model.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'overview_tab.dart';
import 'customers_tab.dart';
import 'trends_tab.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final CustomerViewModel _viewModel;
  late final TabController _tabController;

  static const Color bg = Color(0xFFFFFFFF);
  static const Color purple = Color(0xFF6D28D9);
  static const Color gray = Color(0xFF6B7280);

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
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _buildContent(isWide: isWide);

        if (isWide) {
          return Scaffold(
            backgroundColor: bg,
            body: Row(
              children: [
                const SizedBox(
                  width: 240,
                  child: AppDrawer(activeItem: 'Customers'),
                ),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bg,
          drawer: const AppDrawer(activeItem: 'Customers'),
          body: body,
        );
      },
    );
  }

  Widget _buildContent({required bool isWide}) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.analytics == null) {
            return const Center(child: CircularProgressIndicator(color: purple));
          }
          if (_viewModel.hasError && _viewModel.analytics == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(_viewModel.errorMessage ?? 'Failed to load', style: const TextStyle(color: gray)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _viewModel.loadAnalytics(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: AppTopBar(
                  title: 'Customer Analysis',
                  showMenuButton: !isWide,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: gray,
                  indicator: BoxDecoration(
                    color: purple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
