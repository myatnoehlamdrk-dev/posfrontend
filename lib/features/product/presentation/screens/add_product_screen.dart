import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/features/product/data/models/product_create_models.dart';
import 'package:posfrontend/features/product/domain/entities/product_detail.dart';
import 'package:posfrontend/features/product/presentation/viewmodels/add_product_view_model.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

const Color kPurple700 = Color(0xFF7C3AED);
const Color kPurple600 = Color(0xFF6D28D9);
const Color kPurple900 = Color(0xFF5B21B6);
const Color kLightPurple = Color(0xFFF5F0FF);

class AddProductScreen extends StatefulWidget {
  final ProductDetailEntity? existingProduct;
  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AddProductViewModel _vm;
  bool _saving = false;

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
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 768;
            final body = _content();
            final scaffold = isWide
                ? Scaffold(
                    backgroundColor: Colors.white,
                    body: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          width: 240,
                          child: AppDrawer(activeItem: 'Product'),
                        ),
                        Expanded(child: body),
                      ],
                    ),
                    bottomNavigationBar: _createButton(),
                  )
                : Scaffold(
                    key: _scaffoldKey,
                    backgroundColor: Colors.white,
                    drawer: const AppDrawer(activeItem: 'Product'),
                    body: body,
                    bottomNavigationBar: _createButton(),
                  );
            return scaffold;
          },
        );
      },
    );
  }

  Widget _content() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTopBar(
              title: widget.existingProduct != null ? 'Update Product' : 'Create Product',
              showMenuButton: false,
              showBackButton: true,
            ),
            const SizedBox(height: 20),
            FormCard(
              label: 'Inventory Type',
              helper: 'Choose which inventory this product belongs to.',
              child: _inventoryTypeToggle(),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Product Image',
              helper: 'Upload a product photo from your device.',
              child: _imageSection(),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Basic Info',
              child: _basicInfo(),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Category & Package',
              child: _categoryPackage(),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Variants, Stock & Price',
              helper:
                  'Split total stock into sizes and colors. Each variant has its own quantity and price.',
              child: _variantsSection(),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Supply Chain',
              helper: 'Supplier is optional.',
              child: _supplyChain(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _inventoryTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: kLightPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleOption('self', 'Self Inventory'),
          _toggleOption('public', 'Public Inventory'),
        ],
      ),
    );
  }

  Widget _toggleOption(String value, String label) {
    final selected = _vm.inventoryType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_vm.inventoryType == value) return;
          _vm.setInventoryType(value);
        },
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: selected ? kPurple700 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : kPurple600,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageSection() {
    final hasPreview = _vm.imageFile != null || (_vm.imageUrl?.isNotEmpty ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _vm.uploading ? null : () async {
            await _vm.pickAndUpload();
            if (!mounted) return;
            if (_vm.errorMessage == null) {
              showSuccessMessage(context, 'Image uploaded');
            } else {
              _showError();
              _vm.resetError();
            }
          },
          child: _DashedBox(
            child: hasPreview
                ? RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _vm.imageFile != null
                          ? (kIsWeb
                              ? Image.network(
                                  _vm.imageFile!.path,
                                  key: _vm.imageKey,
                                  height: 160,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  _vm.imageFile!,
                                  key: _vm.imageKey,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ))
                          : Image.network(
                              resolveMediaUrl(_vm.imageUrl!)!,
                              key: _vm.imageKey,
                              height: 160,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : const Center(
                                          child: CircularProgressIndicator(
                                            color: kPurple700,
                                          ),
                                        ),
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    size: 42, color: kPurple700),
                              ),
                            ),
                    ),
                  )
                : _vm.uploading
                    ? const CircularProgressIndicator(color: kPurple700)
                    : Column(
                        children: const [
                          Icon(Icons.image_outlined, size: 42, color: kPurple700),
                          SizedBox(height: 10),
                          Text(
                            'Tap to choose an image file',
                            style: TextStyle(fontSize: 14, color: kGray),
                          ),
                        ],
                      ),
          ),
        ),
        if (_vm.imageUrl?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _vm.imageUrl!,
              style: const TextStyle(fontSize: 12, color: kGray),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _basicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('Product Name', _vm.name, 'e.g. Wireless Headphones Pro', req: true),
        const SizedBox(height: 16),
        _field('Brand', _vm.brand, 'e.g. SoundMax', req: true),
        const SizedBox(height: 16),
        _field('SKU', _vm.sku, 'e.g. SM-WHP-001', req: true),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Is Set / Bundle',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTitle),
            ),
            Switch(
              value: _vm.isSet,
              onChanged: _vm.setIsSet,
              activeThumbColor: kPurple700,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._vm.variants.asMap().entries.map((e) {
          final i = e.key;
          final v = e.value;
          return _VariantTile(
            key: ValueKey('variant_${i}_${v.size}_${v.color}_${v.quantity}_${v.price}'),
            index: i,
            variant: v,
            sizeOptions: AddProductViewModel.sizeOptions,
            colorOptions: AddProductViewModel.colorOptions,
            onChanged: (nv) => _vm.onVariantChanged(i, nv),
            onRemove: _vm.variants.length > 1 ? () => _vm.removeVariant(i) : null,
          );
        }),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _vm.addVariant,
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: kPurple700, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                '+ Add Variant',
                style: TextStyle(
                  color: kPurple700,
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
            color: kLightPurple,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Text(
                'Total Stock',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kPurple900),
              ),
              const Spacer(),
              Text(
                '$_totalStock',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPurple900),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _supplyChain() {
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
                      hint: const Text('Select a supplier...', style: TextStyle(color: kGray, fontSize: 14)),
                      items: _vm.suppliers.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, style: const TextStyle(fontSize: 14)),
                      )).toList(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: kPurple700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '+ Add',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
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
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                          decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add New Supplier',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kTitle),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(Icons.close, color: kGray),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _field('Supplier Name', nameController, 'e.g. Golden Harvest Co.', req: true),
                      const SizedBox(height: 16),
                      _field('Contact / Phone', phoneController, 'e.g. 09-1234-5678'),
                      const SizedBox(height: 16),
                      _field('Address', addressController, 'e.g. No.12, Market St, Yangon'),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: savingSupplier ? null : () async {
                            if (nameController.text.isNotEmpty) {
                              setSheetState(() => savingSupplier = true);
                              try {
                                final dio = ApiClient.create();
                                final resp = await dio.post('/api/suppliers', data: {
                                  'name': nameController.text.trim(),
                                  'contact': phoneController.text.trim(),
                                  'address': addressController.text.trim(),
                                });
                                final data = resp.data;
                                if (data is Map<String, dynamic>) {
                                  final newSupplier = SupplierOption(
                                    id: (data['id'] ?? '').toString(),
                                    name: data['name'] ?? nameController.text.trim(),
                                  );
                                  _vm.addSupplier(newSupplier);
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                              } on ApiException catch (e) {
                                if (ctx.mounted) {
                                  showErrorMessage(ctx, e.message);
                                }
                              } finally {
                                if (ctx.mounted) setSheetState(() => savingSupplier = false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPurple700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              : const Text('Save Supplier', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _field(String label, TextEditingController c, String hint,
      {bool req = false, TextInputType? kt}) {
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

  Widget _dropdown(String label, String? value, List<String> items,
      ValueChanged<String?>? onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, req: label.contains('*')),
        const SizedBox(height: 8),
        DropdownField(
          value: value,
          hint: 'Select',
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _label(String text, {bool req = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: kTitle,
          ),
        ),
        if (req)
          const Text(' *', style: TextStyle(color: kRed, fontSize: 14)),
      ],
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kGray, fontSize: 14),
      filled: true,
      fillColor: kBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPurple700),
      ),
    );
  }

  Widget _createButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: _saving ? null : kPurpleGradient,
          color: _saving ? kGray : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _saving ? null : () async {
              setState(() => _saving = true);
              try {
                final success = await _vm.save(existingProduct: widget.existingProduct);
                if (!mounted) return;
                if (success) {
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
                      widget.existingProduct != null ? 'Update Product' : 'Create Product',
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
      _qty.text = widget.variant.quantity.toString();
      _price.text = widget.variant.price.toString();
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
    final colorLabels = widget.colorOptions.map((c) => c.label).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Variant ${widget.index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTitle,
                ),
              ),
              const Spacer(),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: const Icon(Icons.close, size: 18, color: kGray),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniDropdown(
                  'Size',
                  _size,
                  widget.sizeOptions,
                  (v) {
                    _size = v ?? '';
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _colorDropdown(colorLabels),
              ),
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
                child: _miniField('Price', _price,
                    const TextInputType.numberWithOptions(decimal: true), _emit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: kGray)),
        const SizedBox(height: 4),
        DropdownField(
          value: value.isEmpty ? null : value,
          hint: 'Select',
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _colorDropdown(List<String> colorLabels) {
    final swatch = widget.colorOptions
        .firstWhere(
          (c) => c.label == _color,
          orElse: () => const ProductColorOption('', Color(0xFF9E9E9E)),
        )
        .color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Color', style: const TextStyle(fontSize: 12, color: kGray)),
            const SizedBox(width: 6),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: kBorder),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        DropdownField(
          value: _color.isEmpty ? null : _color,
          hint: 'Select',
          items: colorLabels,
          onChanged: (v) {
            _color = v ?? '';
            _emit();
          },
        ),
      ],
    );
  }

  Widget _miniField(String label, TextEditingController c, TextInputType kt,
      VoidCallback onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kGray)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          keyboardType: kt,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(color: kGray, fontSize: 13),
            filled: true,
            fillColor: kBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBox extends StatelessWidget {
  final Widget child;
  const _DashedBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kPurple700.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const double dash = 6;
    const double gap = 4;
    const r = 16.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          const Radius.circular(r),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = dist + dash;
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
