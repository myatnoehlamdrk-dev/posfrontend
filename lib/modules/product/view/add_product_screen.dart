import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository_impl.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/product/model/product_create_models.dart';
import 'package:posfrontend/modules/product/model/product_detail_models.dart' hide ProductVariant;
import 'package:posfrontend/modules/product/repository/product_create_repository_impl.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

const Color kPurple700 = Color(0xFF7C3AED);
const Color kPurple600 = Color(0xFF6D28D9);
const Color kPurple900 = Color(0xFF5B21B6);
const Color kLightPurple = Color(0xFFF5F0FF);

class AddProductScreen extends StatefulWidget {
  final LoginResponse? user;
  final ProductDetail? existingProduct;
  const AddProductScreen({super.key, this.user, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProductCreateRepositoryImpl _repository = ProductCreateRepositoryImpl();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _sku = TextEditingController();
  final TextEditingController _supplier = TextEditingController();
  final TextEditingController _supplierContact = TextEditingController();
  final TextEditingController _supplierSince = TextEditingController();
  final TextEditingController _supplierAddress = TextEditingController();
  final FocusNode _imageFocus = FocusNode();

  bool _isSet = false;
  String _inventoryType = 'self';

  List<Category> _categories = [];
  Category? _selectedCategory;
  List<PackageOption> _packages = [];
  PackageOption? _selectedPackage;

  File? _imageFile;
  String? _imageUrl;
  String? _imageDeleteUrl;
  bool _uploading = false;
  Key _imageKey = UniqueKey();

  final List<ProductVariant> _variants = [
    ProductVariant(size: 'Small', color: 'Black'),
  ];

  static const List<String> _sizeOptions = [
    'Individual',
    'Family Pack',
    'Small',
    'Medium',
    'Large',
    'XL',
    'Standard',
    'Premium',
    'Enterprise',
  ];

  static const List<ProductColorOption> _colorOptions = [
    ProductColorOption('Black', Color(0xFF000000)),
    ProductColorOption('White', Color(0xFFFFFFFF)),
    ProductColorOption('Gray', Color(0xFF808080)),
    ProductColorOption('Navy Blue', Color(0xFF000080)),
    ProductColorOption('Royal Blue', Color(0xFF4169E1)),
    ProductColorOption('Red', Color(0xFFE53935)),
    ProductColorOption('Green', Color(0xFF43A047)),
    ProductColorOption('Yellow', Color(0xFFFDD835)),
    ProductColorOption('Orange', Color(0xFFFB8C00)),
    ProductColorOption('Brown', Color(0xFF795548)),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _name.text = p.name;
      _brand.text = p.brand;
      _sku.text = p.sku;
      _supplier.text = p.supplierName;
      _supplierContact.text = p.supplierContact;
      _supplierSince.text = p.supplierSince;
      _supplierAddress.text = p.supplierAddress;
      _imageUrl = p.imageUrl;
      _imageDeleteUrl = p.imageDeleteUrl;
      _variants.clear();
      for (final v in p.variants) {
        _variants.add(ProductVariant(
          size: v.size,
          color: v.color,
          quantity: v.quantity,
          price: v.price,
        ));
      }
      if (_variants.isEmpty) {
        _variants.add(ProductVariant(size: 'Small', color: 'Black'));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _sku.dispose();
    _supplier.dispose();
    _supplierContact.dispose();
    _supplierSince.dispose();
    _supplierAddress.dispose();
    _imageFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryRepositoryImpl().getCategories(type: _inventoryType);
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _selectedCategory = null;
        _packages = [];
        _selectedPackage = null;
      });
    } on ApiException {
      // Leave categories empty on failure.
    }
  }

  Future<void> _onCategoryChanged(Category? cat) async {
    setState(() => _selectedCategory = cat);
    if (cat == null) {
      setState(() {
        _packages = [];
        _selectedPackage = null;
      });
      return;
    }
    try {
      final pkgs = await _repository.getPackages(cat.id);
      if (!mounted) return;
      setState(() {
        _packages = pkgs;
        _selectedPackage = null;
      });
    } on ApiException {
      // Leave packages empty on failure.
    }
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() {
      _imageFile = File(xfile.path);
      _imageKey = UniqueKey();
      _uploading = true;
    });
    try {
      final result = await ImgbbRepositoryImpl().uploadImage(
        bytes,
        fileName: xfile.name,
      );
      if (!mounted) return;
      setState(() {
        _imageUrl = result.url;
        _imageDeleteUrl = result.deleteUrl;
        _imageKey = UniqueKey();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _onVariantChanged(int index, ProductVariant v) {
    setState(() {
      _variants[index] = v;
    });
  }

  void _addVariant() {
    setState(() => _variants.add(ProductVariant(size: 'Small', color: 'Black')));
  }

  void _removeVariant(int index) {
    setState(() => _variants.removeAt(index));
  }

  Future<void> _save() async {
    if (_uploading) {
      _snack('Please wait for image upload to finish');
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack('Product name is required');
      return;
    }
    final valid = _variants
        .where((v) => v.size.isNotEmpty && v.quantity > 0 && v.price > 0)
        .toList();
    if (valid.isEmpty) {
      _snack('Add at least one variant with a size, quantity and price');
      return;
    }

    final req = ProductCreateRequest(
      isSet: _isSet,
      name: name,
      imageUrl: _imageUrl ?? '',
      brand: _brand.text.trim(),
      inventoryType: _inventoryType,
      categoryId: _selectedCategory?.id ?? '',
      packageId: _selectedPackage?.id ?? '',
      variants: valid,
      sku: _sku.text.trim(),
      supplierName: _supplier.text.trim(),
      supplierContact: _supplierContact.text.trim(),
      supplierSince: _supplierSince.text.trim(),
      supplierAddress: _supplierAddress.text.trim(),
      imageDeleteUrl: _imageDeleteUrl ?? '',
    );

    try {
      if (widget.existingProduct != null) {
        await _repository.updateProduct(widget.existingProduct!.id, req);
        if (!mounted) return;
        _snack('Product updated');
      } else {
        await _repository.createProduct(req);
        if (!mounted) return;
        _snack('Product created');
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int get _totalStock =>
      _variants.fold(0, (s, v) => s + (v.quantity > 0 ? v.quantity : 0));

  @override
  Widget build(BuildContext context) {
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
                    SizedBox(
                      width: 240,
                      child: AppDrawer(user: widget.user, activeItem: 'Product'),
                    ),
                    Expanded(child: body),
                  ],
                ),
                bottomNavigationBar: _createButton(),
              )
            : Scaffold(
                key: _scaffoldKey,
                backgroundColor: Colors.white,
                drawer: AppDrawer(user: widget.user, activeItem: 'Product'),
                body: body,
                bottomNavigationBar: _createButton(),
              );
        return scaffold;
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
              user: widget.user,
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
    final selected = _inventoryType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_inventoryType == value) return;
          setState(() => _inventoryType = value);
          _loadCategories();
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
    final hasPreview = _imageFile != null || (_imageUrl?.isNotEmpty ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _uploading ? null : _pickAndUpload,
            child: _DashedBox(
              child: hasPreview
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, key: _imageKey, height: 160, fit: BoxFit.cover)
                      : Image.network(
                          _imageUrl!,
                          key: _imageKey,
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
                    )
                : _uploading
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
        if (_imageUrl?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _imageUrl!,
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
        _field('Product Name', _name, 'e.g. Wireless Headphones Pro', req: true),
        const SizedBox(height: 16),
        _field('Brand', _brand, 'e.g. SoundMax', req: true),
        const SizedBox(height: 16),
        _field('SKU', _sku, 'e.g. SM-WHP-001', req: true),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Is Set / Bundle',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTitle),
            ),
            Switch(
              value: _isSet,
              onChanged: (v) => setState(() => _isSet = v),
              activeThumbColor: kPurple700,
              activeTrackColor: const Color(0xFFC4B5FD),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryPackage() {
    final categoryLabels = _categories.map((c) => c.name).toList();
    final selectedCategoryLabel = _selectedCategory?.name;
    final packageLabels = _packages.map((p) => p.name).toList();
    final selectedPackageLabel = _selectedPackage?.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dropdown(
          'Category',
          selectedCategoryLabel,
          categoryLabels,
          _categories.isEmpty
              ? null
              : (v) => _onCategoryChanged(
                  _categories.firstWhere((c) => c.name == v),
                ),
        ),
        const SizedBox(height: 16),
        _dropdown(
          'Package',
          selectedPackageLabel,
          packageLabels,
          _packages.isEmpty || _selectedCategory == null
              ? null
              : (v) => setState(() {
                  _selectedPackage = _packages.firstWhere((p) => p.name == v);
                }),
        ),
      ],
    );
  }

  Widget _variantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._variants.asMap().entries.map((e) {
          final i = e.key;
          final v = e.value;
          return _VariantTile(
            index: i,
            variant: v,
            sizeOptions: _sizeOptions,
            colorOptions: _colorOptions,
            onChanged: (nv) => _onVariantChanged(i, nv),
            onRemove: _variants.length > 1 ? () => _removeVariant(i) : null,
          );
        }),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _addVariant,
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
        _field('Supplier (optional)', _supplier,
            'Type a supplier name (created if new)'),
        const SizedBox(height: 16),
        _field('Contact Number', _supplierContact, 'Supplier phone number'),
        const SizedBox(height: 16),
        _field('Supplier Since', _supplierSince, 'e.g. 2024-01-15'),
        const SizedBox(height: 16),
        _field('Supplier Address', _supplierAddress, 'Supplier address'),
      ],
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
          gradient: kPurpleGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _save,
            child: Center(
              child: Text(
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
  final ProductVariant variant;
  final List<String> sizeOptions;
  final List<ProductColorOption> colorOptions;
  final ValueChanged<ProductVariant> onChanged;
  final VoidCallback? onRemove;

  const _VariantTile({
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
  void dispose() {
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      ProductVariant(
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
