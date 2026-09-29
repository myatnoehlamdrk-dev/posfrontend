import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/data/repositories/product_repository_impl.dart';
import 'package:posfrontend/features/product/presentation/screens/add_product_screen.dart';
import 'package:posfrontend/features/product/presentation/viewmodels/product_detail_view_model.dart';
import 'package:posfrontend/features/product/domain/entities/product_detail.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductDetailViewModel _viewModel;

  // Brightness-dependent tokens. The `k*` constants from
  // inventory_form_widgets.dart are light-only, so text and surfaces here read
  // the active palette instead.
  AppPalette get _p => context.palette;
  Color get _titleColor => _p.textPrimary;
  Color get _mutedColor => _p.textSecondary;
  Color get _accentColor => _p.primary;
  Color get _borderColor => _p.border;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductDetailViewModel(
      repository: ProductDetailRepositoryImpl(),
      productId: widget.productId,
    );
    _viewModel.load();
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
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 768;
            final body = _content(isWide: isWide);

            return Scaffold(
              backgroundColor: _p.scaffoldBg,
              body: SafeArea(child: body),
            );
          },
        );
      },
    );
  }

  Widget _content({required bool isWide}) {
    return Column(
      children: [
        AppScreenTopBar(
          title: 'Product Detail',
          showBackButton: true,
          showMenuButton: false,
        ),
        Expanded(
          child: RefreshableBody(
            onRefresh: _viewModel.load,
            child: _viewModel.isLoading
                ? SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _accentColor,
                      ),
                    ),
                  )
                : _viewModel.hasError
                ? SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _viewModel.errorMessage!,
                            style: TextStyle(color: _p.dangerFg),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _viewModel.load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _viewModel.detail == null
                ? SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _accentColor,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroImage(),
                        const SizedBox(height: 16),
                        _summaryCard(),
                        const SizedBox(height: 16),
                        _segmented(),
                        const SizedBox(height: 16),
                        _tabContent(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _heroImage() {
    final d = _viewModel.detail!;
    final color = CatalogProductView.colorFor(d.categoryName);
    final hasImage = d.imageUrl != null;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color,
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Image.network(
                  d.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _heroFallback(color),
                )
              : _heroFallback(color),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddProductScreen(existingProduct: _viewModel.detail),
                ),
              );
              if (mounted) _viewModel.load();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroFallback(Color color) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2,
          color: Colors.white.withValues(alpha: 0.9),
          size: 84,
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: _p.cardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _viewModel.detail!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          PriceText(
            _viewModel.detail!.price,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmented() {
    const tabs = ['Info', 'Stock', 'Supplier'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _p.chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _viewModel.tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _viewModel.setTabIndex(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _p.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: _p.cardShadow,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: active ? _accentColor : _mutedColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _tabContent() {
    switch (_viewModel.tabIndex) {
      case 1:
        return _stockTab();
      case 2:
        return _supplierTab();
      default:
        return _infoTab();
    }
  }

  Widget _infoTab() {
    final d = _viewModel.detail!;
    final variants = d.variants;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 12),
        // Category, inventory and package are contextual tags, not product
        // attributes, so they render as pills here rather than attribute rows.
        _overviewChips(d),
        const SizedBox(height: 24),
        Text(
          'Identification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.qr_code, 'SKU', d.sku),
          _row(Icons.layers, 'Is Set / Bundle', d.isBundle),
        ]),
        const SizedBox(height: 24),
        Text(
          'Attributes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.inventory_2, 'Product Name', d.name),
          _row(Icons.business, 'Brand', d.brand),
          // Size and colour hold several values (each variant may carry its own),
          // so they render as chips, one per option, rather than single rows.
          _multiValueRow(Icons.color_lens, 'Color', _colorValues(d)),
          _multiValueRow(Icons.straighten, 'Size', _sizeValues(d)),
        ]),
        if (d.createdBy.isNotEmpty || d.updatedBy.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Audit Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 12),
          _card([
            if (d.createdBy.isNotEmpty)
              _row(Icons.person_add, 'Created By', d.createdBy),
            if (d.createdAt.isNotEmpty)
              _row(Icons.access_time, 'Created At', d.createdAt),
            if (d.updatedBy.isNotEmpty)
              _row(Icons.edit, 'Updated By', d.updatedBy),
            if (d.updatedAt.isNotEmpty)
              _row(Icons.update, 'Updated At', d.updatedAt),
          ]),
        ],
        if (variants.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Variants',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 12),
          ...variants.map(
            (v) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _p.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _p.selectionTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: _accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              v.size.isNotEmpty
                                  ? v.size
                                  : (v.color.isNotEmpty ? v.color : 'Default'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _titleColor,
                            ),
                          ),
                            if (v.color.isNotEmpty && v.size.isNotEmpty)
                              Text(
                                v.color,
                              style: TextStyle(
                                fontSize: 12,
                                color: _mutedColor,
                              ),
                            ),
                          Text(
                            'Qty: ${v.quantity}',
                            style: TextStyle(fontSize: 12, color: _mutedColor),
                          ),
                        ],
                      ),
                    ),
                    PriceText(
                      v.price,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _accentColor,
                      ),
                    ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _stockTab() {
    final d = _viewModel.detail!;
    final pct = d.stockAvailable / d.maxCapacity;
    // Status hues come from the palette so they stay legible on a dark surface.
    final color = d.stockStatus == 'High Stock'
        ? _p.successFg
        : (d.stockStatus == 'Mid-Cap Stock'
              ? const Color(0xFF60A5FA)
              : (d.stockStatus == 'Low Stock'
                    ? _p.warningFg
                    : _p.dangerFg));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
            boxShadow: _p.cardElevation,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _p.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2, color: _p.successFg),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.stockAvailable}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _titleColor,
                      ),
                    ),
                    Text(
                      'Units in Stock',
                      style: TextStyle(fontSize: 13, color: _mutedColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _p.successBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _p.successFg,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Stock Info',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.check_box, 'Available', '${d.stockAvailable} units'),
          _row(Icons.remove_circle, 'Minimum', '${d.minStock} units'),
          _row(Icons.inventory, 'Maximum', '${d.maxCapacity} units'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
            boxShadow: _p.cardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Current Stock Status',
                    style: TextStyle(fontSize: 14, color: _mutedColor),
                  ),
                  const Spacer(),
                  Text(
                    d.stockStatus,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: _p.chipBg,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _supplierTab() {
    final d = _viewModel.detail!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supplier Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.badge, 'Supplier ID', d.supplierId),
          _row(Icons.business, 'Supplier Name', d.supplierName),
          _row(Icons.description, 'Contact No', d.contractNumber),
          _row(Icons.calendar_today, 'Supplier Since', d.supplierSince),
        ]),
      ],
    );
  }

  Widget _overviewChips(ProductDetailEntity d) {
    final pills = <Widget>[];
    if (d.categoryName.isNotEmpty && d.categoryName != '—') {
      pills.add(_pill(Icons.category, d.categoryName));
    }
    if (d.inventoryType.isNotEmpty && d.inventoryType != '—') {
      pills.add(_pill(Icons.store, d.inventoryType));
    }
    if (d.packageName.isNotEmpty && d.packageName != '—') {
      pills.add(_pill(Icons.inventory, d.packageName));
    }
    if (pills.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: pills);
  }

  Widget _pill(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _p.selectionTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _accentColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _accentColor,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _colorValues(ProductDetailEntity d) =>
      _optionValues([d.color, ...d.variants.map((v) => v.color)]);

  List<String> _sizeValues(ProductDetailEntity d) =>
      _optionValues([d.size, ...d.variants.map((v) => v.size)]);

  /// Distinct, non-empty options in first-seen order. A product may carry the
  /// same value both at the top level and on its variants, so they're merged
  /// rather than repeated.
  List<String> _optionValues(List<String> all) {
    final seen = <String>{};
    final out = <String>[];
    for (final v in all) {
      if (v.isEmpty || v == '—') continue;
      if (seen.add(v)) out.add(v);
    }
    return out;
  }

  Widget _multiValueRow(IconData icon, String label, List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _accentColor),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: _mutedColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: values.isEmpty
                ? Text(
                    '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    children: values.map(_valueChip).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _valueChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _p.selectionTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _titleColor,
        ),
      ),
    );
  }

  Widget _card(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: _p.cardElevation,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: _borderColor),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _accentColor),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: _mutedColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
