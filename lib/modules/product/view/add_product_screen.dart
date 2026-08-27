import 'package:flutter/material.dart';
import 'package:posfrontend/modules/inventory/view/inventory_sidebar.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/product/model/product_create_models.dart';
import 'package:posfrontend/modules/product/repository/product_create_repository_impl.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

const Color kPurple700 = Color(0xFF7C3AED);
const Color kPurple600 = Color(0xFF6D28D9);
const Color kPurple900 = Color(0xFF5B21B6);
const Color kLightPurple = Color(0xFFF5F0FF);

class AddProductScreen extends StatefulWidget {
  final LoginResponse? user;
  const AddProductScreen({super.key, this.user});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _imageUrl = TextEditingController();
  final TextEditingController _stock = TextEditingController(text: '0');
  final TextEditingController _price = TextEditingController(text: '0.00');
  final TextEditingController _sku = TextEditingController();
  final FocusNode _imageFocus = FocusNode();

  bool _isSet = false;
  String? _category;
  String? _sizeType;
  String? _supplier;
  String? _package;
  final Set<String> _colors = {};

  List<SupplierOption> _suppliers = [];
  List<PackageOption> _packages = [];

  static const String _autoId = 'PRD-009';
  static const String _staffBadge = 'STF-001';

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

  static const List<String> _categoryOptions = [
    'Audio',
    'Charging',
    'Peripherals',
    'Accessories',
  ];

  static const List<ProductColorOption> _colorOptions = [
    ProductColorOption('Matte Black', Color(0xFF1F2937)),
    ProductColorOption('Pearl White', Color(0xFFF9FAFB)),
    ProductColorOption('Space Gray', Color(0xFF4B5563)),
    ProductColorOption('Midnight Blue', Color(0xFF1E3A8A)),
    ProductColorOption('Orange', Color(0xFFF97316)),
    ProductColorOption('Charcoal', Color(0xFF374151)),
    ProductColorOption('Rose Gold', Color(0xFFE8B4B8)),
    ProductColorOption('Violet', Color(0xFF7C3AED)),
    ProductColorOption('Forest Green', Color(0xFF166534)),
    ProductColorOption('Cream', Color(0xFFFDF6E3)),
  ];

  @override
  void initState() {
    super.initState();
    ProductCreateRepositoryImpl().getSuppliers().then((v) {
      if (mounted) setState(() => _suppliers = v);
    });
    ProductCreateRepositoryImpl().getPackages().then((v) {
      if (mounted) setState(() => _packages = v);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _imageUrl.dispose();
    _stock.dispose();
    _price.dispose();
    _sku.dispose();
    _imageFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final req = ProductCreateRequest(
      productId: _autoId,
      isSet: _isSet,
      name: _name.text.trim(),
      imageUrl: _imageUrl.text.trim(),
      brand: _brand.text.trim(),
      categoryId: _category ?? '',
      stock: int.tryParse(_stock.text) ?? 0,
      price: double.tryParse(_price.text) ?? 0.0,
      sku: _sku.text.trim(),
      sizeType: _sizeType ?? '',
      colors: _colors.toList(),
      supplierId:
          _suppliers.where((s) => s.name == _supplier).firstOrNull?.id ?? '',
      packageId:
          _packages.where((p) => p.name == _package).firstOrNull?.id ?? '',
      createdByStaffId: _staffBadge,
    );
    await ProductCreateRepositoryImpl().createProduct(req);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product $_autoId created')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sidebar = InventorySidebar(
      user: widget.user,
      activeItem: 'Product',
      onNavigate: (_) {},
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _content();

        final scaffold = isWide
            ? Scaffold(
                backgroundColor: Colors.white,
                body: Row(children: [sidebar, Expanded(child: body)]),
                bottomNavigationBar: _createButton(),
              )
            : Scaffold(
                key: _scaffoldKey,
                backgroundColor: Colors.white,
                drawer: Drawer(child: sidebar),
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
            _header(),
            const SizedBox(height: 20),
            _autoIdCard(),
            const SizedBox(height: 16),
            _staffCard(),
            const SizedBox(height: 16),
            FormCard(
              label: 'Product Image',
              helper: 'Upload a product photo or paste an image URL.',
              child: _imageSection(),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Basic Info',
              child: _basicInfo(),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Inventory & Specs',
              child: _inventorySpecs(),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Color',
              helper: 'Select one or more product colors.',
              child: _colorSection(),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Supply Chain',
              child: _supplyChain(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: kBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTitle, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'New Product',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
              Text(
                'Create Product',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTitle,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: kPurple700,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _save,
              child: const Center(
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _autoIdCard() {
    return _panel(
      Row(
        children: [
          const Text(
            'AUTO ID',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kGray,
            ),
          ),
          const Spacer(),
          Text(
            _autoId,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPurple600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffCard() {
    return _panel(
      Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: kPurple600,
            child: const Text(
              'JD',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'John Doe',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTitle),
                ),
                SizedBox(height: 2),
                Text(
                  'Admin - Operations',
                  style: TextStyle(fontSize: 13, color: kGray),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kPurple700,
              borderRadius: BorderRadius.circular(20),
            ),
              child: const Text(
              'STF-001',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _imageFocus.requestFocus(),
          child: _DashedBox(
            child: Column(
              children: const [
                Icon(Icons.image_outlined, size: 42, color: kPurple700),
                SizedBox(height: 10),
                Text(
                  'Paste image URL below',
                  style: TextStyle(fontSize: 14, color: kGray),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _imageUrl,
          focusNode: _imageFocus,
          decoration: _decoration('https://...'),
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
        _dropdown('Category', _category, _categoryOptions, (v) => setState(() => _category = v)),
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
              activeTrackColor: Color(0xFFC4B5FD),
            ),
          ],
        ),
      ],
    );
  }

  Widget _inventorySpecs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('Stock *', _stock, '0', req: true, kt: TextInputType.number),
        const SizedBox(height: 16),
        _field('Price (\$) *', _price, '0.00', req: true,
            kt: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 16),
        _field('SKU *', _sku, 'e.g. SM-WHP-001', req: true),
        const SizedBox(height: 16),
        _dropdown('Size / Family Type *', _sizeType, _sizeOptions,
            (v) => setState(() => _sizeType = v)),
      ],
    );
  }

  Widget _colorSection() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colorOptions.map(_colorChip).toList(),
    );
  }

  Widget _colorChip(ProductColorOption c) {
    final selected = _colors.contains(c.label);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _colors.remove(c.label);
        } else {
          _colors.add(c.label);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPurple700.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(color: selected ? kPurple700 : kBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: c.color,
                shape: BoxShape.circle,
                border: Border.all(color: kBorder),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              c.label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? kPurple700 : kTitle,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supplyChain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dropdown('Supplier *', _supplier, _suppliers.map((s) => s.name).toList(),
            (v) => setState(() => _supplier = v)),
        const SizedBox(height: 16),
        _dropdown('Package *', _package, _packages.map((p) => p.name).toList(),
            (v) => setState(() => _package = v)),
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
      ValueChanged<String?> onChanged) {
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

  Widget _panel(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
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
            child: const Center(
              child: Text(
                'Create Product PRD-009',
                style: TextStyle(
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
