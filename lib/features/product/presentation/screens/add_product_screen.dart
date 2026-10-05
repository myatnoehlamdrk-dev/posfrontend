import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/product/data/models/product_create_models.dart';
import 'package:posfrontend/features/product/domain/entities/product_detail.dart';
import 'package:posfrontend/features/product/presentation/viewmodels/add_product_view_model.dart';
import 'package:posfrontend/features/product/presentation/widgets/purchase_item_picker_view.dart';
import 'package:posfrontend/features/purchase/data/repositories/purchase_repository_impl.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/shared/widgets/premium_image_upload.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';


class AddProductScreen extends StatefulWidget {
  final ProductDetailEntity? existingProduct;
  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  late final AddProductViewModel _vm;
  bool _saving = false;

  /// 0 = the normal add-product form, 1 = the purchase-item search page.
  int _addMode = 0;

  /// The pending purchase item the form was seeded from, if any. Completing the
  /// create turns it into a completed purchase item.
  PurchaseOrderEntity? _sourcePurchaseItem;

  @override
  void initState() {
    super.initState();
    _vm = AddProductViewModel();
    _vm.loadInitialData(existingProduct: widget.existingProduct);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  int get _totalStock =>
      _vm.variants.fold(0, (s, v) => s + (v.quantity > 0 ? v.quantity : 0));

  void _showError() {
    if (_vm.errorMessage != null) showErrorMessage(context, _vm.errorMessage!);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final p = context.palette;
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 768;
            final body = _content();
            final bottomBar = _addMode == 0 ? _createButton() : null;
            final scaffold = isWide
                ? Scaffold(
                    backgroundColor: p.scaffoldBg,
                    body: body,
                    bottomNavigationBar: bottomBar,
                  )
                : Scaffold(
                    backgroundColor: p.scaffoldBg,
                    body: body,
                    bottomNavigationBar: bottomBar,
                  );
            return scaffold;
          },
        );
      },
    );
  }

  Widget _content() {
    return SafeArea(
      child: Column(
        children: [
          AppScreenTopBar(
            title: widget.existingProduct != null
                ? 'Update Product'
                : 'Create Product',
            showMenuButton: false,
            showBackButton: true,
          ),
          if (widget.existingProduct == null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _modeSwitch(),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(child: _addMode == 0 ? _normalForm() : _purchasePage()),
        ],
      ),
    );
  }

  /// Two ways to add a product: fill the form directly, or start from an
  /// existing purchase item.
  Widget _modeSwitch() {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _modeOption(0, context.l10n.t('Normal Add'), Icons.edit_outlined),
          _modeOption(
            1,
            context.l10n.t('Purchase Item'),
            Icons.inventory_2_outlined,
          ),
        ],
      ),
    );
  }

  Widget _modeOption(int mode, String label, IconData icon) {
    final p = context.palette;
    final active = _addMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_addMode == mode) return;
          setState(() => _addMode = mode);
        },
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: active ? p.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: p.cardShadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppColors.brandPurple : p.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.brandPurple : p.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _purchasePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('Search Purchase Item'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.t(
              'Pick a pending purchase item to copy its name, stock, price and supplier into the form. It is marked completed once the product is created.',
            ),
            style: TextStyle(
              fontSize: 13,
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PurchaseItemPickerView(onSelected: _onPurchaseItemSelected),
          ),
        ],
      ),
    );
  }

  void _onPurchaseItemSelected(PurchaseOrderEntity order) {
    _vm.applyPurchaseItem(order);
    setState(() {
      _sourcePurchaseItem = order;
      _addMode = 0;
    });
    showSuccessMessage(
      context,
      context.l10n.t('Purchase item copied into the form'),
    );
  }

  /// Marks the purchase item this product came from as completed. A failure
  /// here must not undo a successful product create, so it is swallowed.
  Future<void> _completeSourcePurchaseItem() async {
    final order = _sourcePurchaseItem;
    if (order == null || widget.existingProduct != null) return;
    try {
      await PurchaseRepositoryImpl().updatePurchaseItemStatus(
        id: order.orderId,
        status: 'completed',
      );
    } catch (_) {}
  }

  Widget _normalForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormCard(
            label: context.l10n.t('Inventory Type'),
            helper: context.l10n.t(
              'Choose which inventory this product belongs to.',
            ),
            child: _inventoryTypeDropdown(),
          ),
          const SizedBox(height: 16),
          FormCard(
            label: context.l10n.t('Product Image'),
            helper: context.l10n.t('Upload a product photo from your device.'),
            child: _imageSection(),
          ),
          const SizedBox(height: 16),
          FormCard(label: context.l10n.t('Basic Info'), child: _basicInfo()),
          const SizedBox(height: 16),
          FormCard(
            label: context.l10n.t('Category & Package'),
            child: _categoryPackage(),
          ),
          const SizedBox(height: 16),
          FormCard(
            label: context.l10n.t('Variants, Stock & Price'),
            helper: context.l10n.t(
              'Split total stock into sizes and colors. Each variant has its own quantity and price.',
            ),
            child: _variantsSection(),
          ),
          const SizedBox(height: 16),
          FormCard(
            label: context.l10n.t('Supply Chain'),
            helper: context.l10n.t('Supplier is optional.'),
            child: _supplyChain(),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  static const Map<String, String> _inventoryLabels = {
    'self': 'Self Inventory',
    'public': 'Public Inventory',
  };

  Widget _inventoryTypeDropdown() {
    return _dropdown(
      'Inventory Type',
      _inventoryLabels[_vm.inventoryType] ?? _inventoryLabels['self'],
      _inventoryLabels.values.toList(),
      (v) {
        final entry = _inventoryLabels.entries.firstWhere((e) => e.value == v);
        if (entry.key != _vm.inventoryType) _vm.setInventoryType(entry.key);
      },
    );
  }

  Widget _imageSection() {
    final p = context.palette;
    final file = _vm.imageFile;
    final url = _vm.imageUrl;
    final hasPreview = file != null || (url?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumImageUpload(
          isBusy: _vm.uploading,
          icon: Icons.image_outlined,
          height: 168,
          title: context.l10n.t('Product image'),
          subtitle: context.l10n.t('Tap to choose an image file'),
          hint: context.l10n.t('JPG or PNG up to 5MB'),
          changeLabel: context.l10n.t('Change photo'),
          image: !hasPreview
              ? null
              : RepaintBoundary(
                  child: file != null
                      ? (kIsWeb
                            ? Image.network(
                                file.path,
                                key: _vm.imageKey,
                                height: 168,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                file,
                                key: _vm.imageKey,
                                height: 168,
                                fit: BoxFit.cover,
                              ))
                      : Image.network(
                          resolveMediaUrl(url!)!,
                          key: _vm.imageKey,
                          height: 168,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                              ? child
                              : Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.brandPurple,
                                  ),
                                ),
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 42,
                              color: AppColors.brandPurple,
                            ),
                          ),
                        ),
                ),
          onTap: _vm.uploading
              ? null
              : () async {
                  await _vm.pickAndUpload();
                  if (!mounted) return;
                  if (_vm.errorMessage == null) {
                    showSuccessMessage(
                      context,
                      context.l10n.t('Image uploaded'),
                    );
                  } else {
                    _showError();
                    _vm.resetError();
                  }
                },
        ),
        if (url?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              url!,
              style: TextStyle(fontSize: 12, color: p.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _basicInfo() {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          'Product Name',
          _vm.name,
          'e.g. Wireless Headphones Pro',
          req: true,
        ),
        const SizedBox(height: 16),
        _field('Brand', _vm.brand, 'e.g. SoundMax', req: true),
        const SizedBox(height: 16),
        _field('SKU', _vm.sku, 'e.g. SM-WHP-001', req: true),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.t('Is Set / Bundle'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: p.textPrimary,
              ),
            ),
            Switch(
              value: _vm.isSet,
              onChanged: _vm.setIsSet,
              activeThumbColor: AppColors.brandPurple,
              activeTrackColor: const Color(0xFFC4B5FD),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryPackage() {
    final categoryLabels = _vm.categories.map((c) => c.name).toList();
    final selectedCategoryLabel = _vm.selectedCategory?.name;
    final packageLabels = _vm.packages.map((p) => p.name).toList();
    final selectedPackageLabel = _vm.selectedPackage?.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dropdown(
          'Category *',
          selectedCategoryLabel,
          categoryLabels,
          _vm.categories.isEmpty
              ? null
              : (v) => _vm.onCategoryChanged(
                  _vm.categories.firstWhere((c) => c.name == v),
                ),
        ),
        const SizedBox(height: 16),
        _dropdown(
          'Package *',
          selectedPackageLabel,
          packageLabels,
          _vm.packages.isEmpty || _vm.selectedCategory == null
              ? null
              : (v) => _vm.setSelectedPackage(
                  _vm.packages.firstWhere((p) => p.name == v),
                ),
        ),
      ],
    );
  }

  Widget _variantsSection() {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._vm.variants.asMap().entries.map((e) {
          final i = e.key;
          final v = e.value;
          return _VariantTile(
            key: ValueKey('variant_$i'),
            index: i,
            variant: v,
            sizeOptions: AddProductViewModel.sizeOptions,
            colorOptions: AddProductViewModel.colorOptions,
            onChanged: (nv) => _vm.onVariantChanged(i, nv),
            onRemove: _vm.variants.length > 1
                ? () => _vm.removeVariant(i)
                : null,
          );
        }),
        SizedBox(height: 12),
        GestureDetector(
          onTap: _vm.addVariant,
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.brandPurple, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                context.l10n.t('+ Add Variant'),
                style: TextStyle(
                  color: AppColors.brandPurple,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: p.selectionTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(
                context.l10n.t('Total Stock'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandPurple,
                ),
              ),
              const Spacer(),
              Text(
                context.l10n
                    .t('{v1}')
                    .replaceAll('{v1}', (_totalStock).toString()),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPurple,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _supplyChain() {
    final p = context.palette;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Supplier', req: false),
                  const SizedBox(height: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _vm.selectedSupplierId,
                      hint: Text(
                        context.l10n.t('Select a supplier...'),
                        style: TextStyle(color: p.textSecondary, fontSize: 14),
                      ),
                      items: _vm.suppliers
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _vm.setSelectedSupplier,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: GestureDetector(
                onTap: _showAddSupplierSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    context.l10n.t('+ Add'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showAddSupplierSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    bool savingSupplier = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final p = ctx.palette;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: p.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.t('Add New Supplier'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: p.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Icon(Icons.close, color: p.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _field(
                        'Supplier Name',
                        nameController,
                        'e.g. Golden Harvest Co.',
                        req: true,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        'Contact / Phone',
                        phoneController,
                        'e.g. 09-1234-5678',
                      ),
                      const SizedBox(height: 16),
                      _field(
                        'Address',
                        addressController,
                        'e.g. No.12, Market St, Yangon',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: savingSupplier
                              ? null
                              : () async {
                                  if (nameController.text.isNotEmpty) {
                                    setSheetState(() => savingSupplier = true);
                                    try {
                                      final dio = ApiClient.create();
                                      final resp = await dio.post(
                                        '/suppliers',
                                        data: {
                                          'name': nameController.text.trim(),
                                          'contact': phoneController.text
                                              .trim(),
                                          'address': addressController.text
                                              .trim(),
                                        },
                                      );
                                      final data = resp.data;
                                      if (data is Map<String, dynamic>) {
                                        final newSupplier = SupplierOption(
                                          id: (data['id'] ?? '').toString(),
                                          name:
                                              data['name'] ??
                                              nameController.text.trim(),
                                        );
                                        _vm.addSupplier(newSupplier);
                                      }
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    } on ApiException catch (e) {
                                      if (ctx.mounted) {
                                        showErrorMessage(ctx, e.message);
                                      }
                                    } finally {
                                      if (ctx.mounted)
                                        setSheetState(
                                          () => savingSupplier = false,
                                        );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: savingSupplier
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  context.l10n.t('Save Supplier'),
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _field(
    String label,
    TextEditingController c,
    String hint, {
    bool req = false,
    TextInputType? kt,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, req: req),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          keyboardType: kt,
          decoration: _decoration(hint),
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?>? onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, req: label.contains('*')),
        const SizedBox(height: 8),
        DropdownField(
          value: value,
          hint: context.l10n.t('Select'),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _label(String text, {bool req = false}) {
    final p = context.palette;
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: p.textPrimary,
          ),
        ),
        if (req) Text(' *', style: TextStyle(color: p.dangerFg, fontSize: 14)),
      ],
    );
  }

  InputDecoration _decoration(String hint) {
    final p = context.palette;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: p.textSecondary, fontSize: 14),
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandPurple),
      ),
    );
  }

  Widget _createButton() {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: p.surface,
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: _saving
              ? null
              : LinearGradient(
                  colors: [
                    AppColors.brandPurple,
                    AppColors.brandPurpleDark,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: _saving ? p.textMuted : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      final success = await _vm.save(
                        existingProduct: widget.existingProduct,
                      );
                      if (!mounted) return;
                      if (success) {
                        await _completeSourcePurchaseItem();
                        if (!mounted) return;
                        Navigator.of(context).pop(true);
                      } else {
                        _showError();
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      widget.existingProduct != null
                          ? 'Update Product'
                          : 'Create Product',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VariantTile extends StatefulWidget {
  final int index;
  final ProductCreateVariant variant;
  final List<String> sizeOptions;
  final List<ProductColorOption> colorOptions;
  final ValueChanged<ProductCreateVariant> onChanged;
  final VoidCallback? onRemove;

  const _VariantTile({
    super.key,
    required this.index,
    required this.variant,
    required this.sizeOptions,
    required this.colorOptions,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_VariantTile> createState() => _VariantTileState();
}

class _VariantTileState extends State<_VariantTile> {
  late String _size;
  late String _color;
  late final TextEditingController _qty;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _size = widget.variant.size;
    _color = widget.variant.color;
    _qty = TextEditingController(text: widget.variant.quantity.toString());
    _price = TextEditingController(text: widget.variant.price.toString());
  }

  @override
  void didUpdateWidget(covariant _VariantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variant != oldWidget.variant) {
      _size = widget.variant.size;
      _color = widget.variant.color;
      final nextQty = widget.variant.quantity.toString();
      final nextPrice = widget.variant.price.toString();
      if (_qty.text != nextQty) _qty.text = nextQty;
      if (_price.text != nextPrice) _price.text = nextPrice;
    }
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      ProductCreateVariant(
        size: _size,
        color: _color,
        quantity: int.tryParse(_qty.text) ?? 0,
        price: double.tryParse(_price.text) ?? 0.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colorLabels = widget.colorOptions.map((c) => c.label).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                context.l10n
                    .t('Variant {v1}')
                    .replaceAll('{v1}', (widget.index + 1).toString()),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
              const Spacer(),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Icon(Icons.close, size: 18, color: p.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniDropdown('Size', _size, widget.sizeOptions, (v) {
                  _size = v ?? '';
                  _emit();
                }),
              ),
              const SizedBox(width: 10),
              Expanded(child: _colorDropdown(colorLabels)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniField('Qty', _qty, TextInputType.number, _emit),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniField('Price', _price, TextInputType.number, _emit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: p.textSecondary)),
        const SizedBox(height: 4),
        DropdownField(
          value: value.isEmpty ? null : value,
          hint: context.l10n.t('Select'),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _colorDropdown(List<String> colorLabels) {
    final p = context.palette;
    final swatch = widget.colorOptions
        .firstWhere(
          (c) => c.label == _color,
          orElse: () => ProductColorOption('', p.textMuted),
        )
        .color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.t('Color'),
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
            const SizedBox(width: 6),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: p.border),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        DropdownField(
          value: _color.isEmpty ? null : _color,
          hint: context.l10n.t('Select'),
          items: colorLabels,
          onChanged: (v) {
            _color = v ?? '';
            _emit();
          },
        ),
      ],
    );
  }

  Widget _miniField(
    String label,
    TextEditingController c,
    TextInputType kt,
    VoidCallback onChanged,
  ) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: p.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          keyboardType: kt,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: p.textSecondary, fontSize: 13),
            filled: true,
            fillColor: p.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: p.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: p.border),
            ),
          ),
        ),
      ],
    );
  }
}
