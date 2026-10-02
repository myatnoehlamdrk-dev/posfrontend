import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/l10n/status_l10n.dart';
import 'package:flutter/services.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/features/cart/domain/entities/cart_item_entity.dart';
import 'package:posfrontend/features/cart/presentation/widgets/cart_actions.dart';
import 'package:posfrontend/features/product/data/models/product_create_models.dart';
import 'package:posfrontend/features/product/data/repositories/product_create_repository_impl.dart';
import 'package:posfrontend/features/product/data/repositories/product_repository_impl.dart';
import 'package:posfrontend/features/product/domain/entities/product_detail.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/screens/add_product_screen.dart';
import 'package:posfrontend/features/product/presentation/viewmodels/product_detail_view_model.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_message.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/pressable_card.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

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

  bool _isBuying = false;

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
          title: context.l10n.t('Product Detail'),
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
                      child: CircularProgressIndicator(color: _accentColor),
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
                            child: Text(context.l10n.t('Retry')),
                          ),
                        ],
                      ),
                    ),
                  )
                : _viewModel.detail == null
                ? SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(color: _accentColor),
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
            child: Text(
              context.l10n.t('Active'),
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
              color: AppColors.brandPurple,
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
          context.l10n.t('Overview'),
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
          context.l10n.t('Identification'),
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
          context.l10n.t('Attributes'),
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
            context.l10n.t('Audit Information'),
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
            context.l10n.t('Variants'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 12),
          ...variants.map((v) {
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
                            context.l10n
                                .t('Qty: {v1}')
                                .replaceAll('{v1}', (v.quantity).toString()),
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
                        color: AppColors.brandPurple,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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
              : (d.stockStatus == 'Low Stock' ? _p.warningFg : _p.dangerFg));
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
                      context.l10n
                          .t('{v1}')
                          .replaceAll('{v1}', (d.stockAvailable).toString()),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _titleColor,
                      ),
                    ),
                    Text(
                      context.l10n.t('Units in Stock'),
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
                  context.l10n.t('Active'),
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
          context.l10n.t('Stock Info'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 12),
        _card([
          _row(Icons.check_box, 'Available', '${d.stockAvailable} units'),
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
                    context.l10n.t('Current Stock Status'),
                    style: TextStyle(fontSize: 14, color: _mutedColor),
                  ),
                  const Spacer(),
                  Text(
                    d.stockStatus.localized(context.l10n),
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _stockAddButton()),
            const SizedBox(width: 12),
            Expanded(child: _directBuyButton()),
          ],
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
          context.l10n.t('Supplier Information'),
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

  /// Restocks this product: opens the inline add-stock dialog where every
  /// variant (including currently 0-stock ones) can be topped up freely.
  Future<void> _stockAdd() async {
    if (_isBuying) return;
    final d = _viewModel.detail;
    if (d == null || !mounted) return;
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _RestockDialog(product: d),
    );
    if (added == true && mounted) _viewModel.load();
  }

  /// Buys this product with the regular cart flow: pick variants (or a
  /// quantity for simple products), add the items to a cart card, then run
  /// the sale from there — the same path as the category product list.
  Future<void> _directBuy() async {
    if (_isBuying) return;
    final d = _viewModel.detail;
    if (d == null || !mounted) return;
    final items = await _buildCartItems(d);
    if (items.isEmpty || !mounted) return;
    setState(() => _isBuying = true);
    try {
      await addItemsToCart(context, items, d.name);
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  /// Resolves the single product into cart items, opening the variant picker
  /// (or the quantity picker) first.
  Future<List<CartItemEntity>> _buildCartItems(ProductDetailEntity d) async {
    if (d.variants.isNotEmpty) {
      final picks = await _openVariantPicker(d);
      if (picks == null || picks.isEmpty) return const [];
      return picks
          .map(
            (p) => CartItemEntity(
              productId: d.id,
              productName: d.name,
              imageUrl: d.imageUrl,
              unitPrice: p.price,
              quantity: p.qty,
              category: d.categoryName,
              size: p.size.isNotEmpty ? p.size : null,
              color: p.color.isNotEmpty ? p.color : null,
            ),
          )
          .toList();
    }
    final qty = await _pickQuantity(d);
    if (qty <= 0) return const [];
    return [
      CartItemEntity(
        productId: d.id,
        productName: d.name,
        imageUrl: d.imageUrl,
        unitPrice: d.price,
        quantity: qty,
        category: d.categoryName,
      ),
    ];
  }

  Future<List<VariantPick>?> _openVariantPicker(ProductDetailEntity d) {
    return showVariantPicker(
      context,
      productName: d.name,
      productStock: d.stockAvailable,
      variants: d.variants
          .map(
            (v) => VariantOption(
              size: v.size,
              color: v.color,
              quantity: v.quantity,
              price: v.price,
            ),
          )
          .toList(),
    );
  }

  Future<int> _pickQuantity(ProductDetailEntity d) async {
    if (d.stockAvailable <= 0) {
      showErrorMessage(
        context,
        context.l10n
            .t('{v1} is out of stock')
            .replaceAll('{v1}', (d.name).toString()),
      );
      return 0;
    }
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => _QuantityPickDialog(
        productName: d.name,
        price: d.price,
        maxQty: d.stockAvailable,
      ),
    );
    return picked ?? 0;
  }

  Widget _stockAddButton() {
    return OutlinedButton.icon(
      onPressed: _isBuying ? null : _stockAdd,
      style: OutlinedButton.styleFrom(
        foregroundColor: _accentColor,
        side: BorderSide(color: _accentColor.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.add_chart, size: 18),
      label: Text(
        context.l10n.t('Stock Add'),
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _directBuyButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: _isBuying
            ? null
            : LinearGradient(
                colors: [AppColors.primaryLight, _accentColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _isBuying ? _p.textMuted : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isBuying ? null : _directBuy,
          child: Center(
            child: _isBuying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.t('Direct Buy'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
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

/// Quantity picker for products that carry no variants. The stepper and field
/// mirror the variant picker so every buying entry point reads the same way.
class _QuantityPickDialog extends StatefulWidget {
  final String productName;
  final double price;
  final int maxQty;

  const _QuantityPickDialog({
    required this.productName,
    required this.price,
    required this.maxQty,
  });

  @override
  State<_QuantityPickDialog> createState() => _QuantityPickDialogState();
}

class _QuantityPickDialogState extends State<_QuantityPickDialog> {
  AppPalette get _p => context.palette;
  Color get _mutedColor => _p.textSecondary;
  Color get _accentColor => _p.primary;
  Color get _titleColor => _p.textPrimary;

  final TextEditingController _ctrl = TextEditingController(text: '1');
  int _qty = 1;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setQty(int qty) {
    if (qty < 0) qty = 0;
    if (qty > widget.maxQty) qty = widget.maxQty;
    setState(() {
      _qty = qty;
      _ctrl.value = TextEditingValue(
        text: '$qty',
        selection: TextSelection.collapsed(offset: '$qty'.length),
      );
    });
  }

  void _fromCtrl(String txt) {
    _setQty(int.tryParse(txt) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _p.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.t('Choose Quantity'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            widget.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: _mutedColor),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n
                    .t('Stock: {v1}')
                    .replaceAll('{v1}', (widget.maxQty).toString()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _accentColor,
                ),
              ),
              const Spacer(),
              PriceText(
                widget.price,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _p.borderStrong),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _stepBtn(
                    Icons.remove,
                    _qty > 0 ? () => _setQty(_qty - 1) : null,
                  ),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: _fromCtrl,
                    ),
                  ),
                  _stepBtn(
                    Icons.add,
                    _qty < widget.maxQty ? () => _setQty(_qty + 1) : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: _mutedColor),
          child: Text(context.l10n.t('Cancel')),
        ),
        FilledButton(
          onPressed: _qty > 0 ? () => Navigator.of(context).pop(_qty) : null,
          style: FilledButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: Colors.white,
          ),
          child: Text(context.l10n.t('Add')),
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return PressableCard(
      onTap: onTap,
      haptic: HapticFeedback.selectionClick,
      pressedScale: 0.88,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? _p.borderStrong : _mutedColor,
        ),
      ),
    );
  }
}

/// Inline restock dialog. Unlike the shopping variant picker, every variant —
/// including ones currently at 0 stock — can be topped up by any amount.
class _RestockDialog extends StatefulWidget {
  final ProductDetailEntity product;

  const _RestockDialog({required this.product});

  @override
  State<_RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<_RestockDialog> {
  AppPalette get _p => context.palette;
  Color get _mutedColor => _p.textSecondary;
  Color get _accentColor => _p.primary;
  Color get _titleColor => _p.textPrimary;
  Color get _borderColor => _p.border;

  late final List<TextEditingController> _addControllers;
  bool _saving = false;
  final ProductCreateRepositoryImpl _repository = ProductCreateRepositoryImpl();

  ProductDetailEntity get _product => widget.product;

  @override
  void initState() {
    super.initState();
    _addControllers = _product.variants.isEmpty
        ? [TextEditingController()]
        : List.generate(
            _product.variants.length,
            (_) => TextEditingController(),
          );
  }

  @override
  void dispose() {
    for (final c in _addControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _variantLabelFor(int i) {
    final v = _product.variants[i];
    final size = v.size.trim();
    final color = v.color.trim();
    if (size.isEmpty && color.isEmpty) return 'Variant ${i + 1}';
    if (size.isEmpty) return color;
    if (color.isEmpty) return size;
    return '$size · $color';
  }

  Future<void> _submit() async {
    if (_addControllers.any(
      (c) =>
          c.text.trim().isNotEmpty && (int.tryParse(c.text.trim()) ?? -1) < 0,
    )) {
      showErrorMessage(context, context.l10n.t('Enter a valid stock amount'));
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.updateProduct(_product.id, _buildRequest());
      if (!mounted) return;
      showSuccessMessage(context, context.l10n.t('Stock added successfully'));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorMessage(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showErrorMessage(context, context.l10n.t('Failed to add stock'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ProductCreateRequest _buildRequest() {
    if (_product.variants.isEmpty) {
      final added = int.tryParse(_addControllers.first.text.trim()) ?? 0;
      return ProductCreateRequest(
        name: _product.name,
        stock: _product.stockAvailable + added,
        variants: const [],
      );
    }
    final variants = _product.variants.asMap().entries.map((e) {
      final v = e.value;
      final added = int.tryParse(_addControllers[e.key].text.trim()) ?? 0;
      return ProductCreateVariant(
        size: v.size,
        color: v.color,
        quantity: v.quantity + added,
        price: v.price,
      );
    }).toList();
    return ProductCreateRequest(name: _product.name, variants: variants);
  }

  @override
  Widget build(BuildContext context) {
    final hasVariants = _product.variants.isNotEmpty;
    return AlertDialog(
      backgroundColor: _p.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.t('Stock Add'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            _product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: _mutedColor),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasVariants)
                _restockRow('Stock', 'Current: ${_product.stockAvailable}', 0)
              else
                ...List.generate(
                  _product.variants.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _restockRow(
                      _variantLabelFor(i),
                      'Current: ${_product.variants[i].quantity}',
                      i,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: _mutedColor),
          child: Text(context.l10n.t('Cancel')),
        ),
        _submitButton(),
      ],
    );
  }

  Widget _restockRow(String label, String current, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(current, style: TextStyle(fontSize: 12, color: _mutedColor)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _addControllers[index],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: context.l10n.t('Add'),
              hintStyle: TextStyle(color: _p.textSecondary, fontSize: 14),
              filled: true,
              fillColor: _p.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accentColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        gradient: _saving
            ? null
            : LinearGradient(
                colors: [AppColors.primaryLight, _accentColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _saving ? _p.textMuted : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _saving ? null : _submit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.l10n.t('Add Stock'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
