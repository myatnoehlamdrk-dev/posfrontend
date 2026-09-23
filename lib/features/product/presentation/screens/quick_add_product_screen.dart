import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/features/product/data/models/product_create_models.dart';
import 'package:posfrontend/features/product/data/repositories/product_create_repository_impl.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';

const Color kPurple700 = Color(0xFF7C3AED);
const Color kPurple600 = Color(0xFF6D28D9);
const Color kPurple900 = Color(0xFF5B21B6);
const Color kLightPurple = Color(0xFFF5F0FF);

class QuickAddProductScreen extends StatefulWidget {
  const QuickAddProductScreen({super.key});

  @override
  State<QuickAddProductScreen> createState() => _QuickAddProductScreenState();
}

class _QuickAddProductScreenState extends State<QuickAddProductScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _stock = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final ProductCreateRepositoryImpl _repository = ProductCreateRepositoryImpl();

  File? _imageFile;
  String? _imageUrl;
  String? _imageDeleteUrl;
  bool _uploading = false;
  bool _saving = false;
  Key _imageKey = UniqueKey();

  @override
  void dispose() {
    _name.dispose();
    _stock.dispose();
    _price.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _sheetOption(
                ctx,
                Icons.photo_camera_outlined,
                'Take a Photo',
                ImageSource.camera,
              ),
              _sheetOption(
                ctx,
                Icons.photo_library_outlined,
                'Upload from Gallery',
                ImageSource.gallery,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? xfile = await picker.pickImage(source: source);
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    setState(() {
      _imageFile = File(xfile.path);
      _imageKey = UniqueKey();
      _uploading = true;
    });
    try {
      final result = await ImgbbRepositoryImpl().uploadImage(bytes, fileName: xfile.name);
      if (!mounted) return;
      setState(() {
        _imageUrl = result.url;
        _imageDeleteUrl = result.deleteUrl;
        _imageKey = UniqueKey();
      });
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _sheetOption(BuildContext ctx, IconData icon, String label, ImageSource source) {
    return ListTile(
      leading: Icon(icon, color: kPurple700),
      title: Text(label, style: const TextStyle(fontSize: 15, color: kTitle)),
      onTap: () => Navigator.pop(ctx, source),
    );
  }

  Future<void> _submit() async {
    if (_uploading) {
      _snack('Please wait for image upload to finish');
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack('Product name is required');
      return;
    }
    final stock = int.tryParse(_stock.text.trim());
    if (stock == null || stock < 0) {
      _snack('Enter a valid stock amount');
      return;
    }
    final price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) {
      _snack('Enter a valid price');
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository.createProduct(
        ProductCreateRequest(
          name: name,
          imageUrl: _imageUrl ?? '',
          stock: stock,
          variants: [
            ProductCreateVariant(quantity: stock, price: price),
          ],
          imageDeleteUrl: _imageDeleteUrl ?? '',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Failed to add product');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(
                title: 'Quick Add Product',
                showMenuButton: false,
                showBackButton: true,
              ),
              const SizedBox(height: 20),
              FormCard(
                label: 'Product Image',
                helper: 'Take a photo or upload an image.',
                child: _imageSection(),
              ),
              const SizedBox(height: 16),
              FormCard(
                label: 'Basic Info',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Product Name', _name, 'e.g. Wireless Headphones Pro', req: true),
                    const SizedBox(height: 16),
                    _field('Stock', _stock, 'e.g. 50', req: true, number: true),
                    const SizedBox(height: 16),
                    _field('Price', _price, 'e.g. 25000', req: true, decimal: true),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _submitButton(),
    );
  }

  Widget _imageSection() {
    final hasPreview = _imageFile != null;
    return GestureDetector(
      onTap: _uploading ? null : _pickImage,
      child: _DashedBox(
        child: hasPreview
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  key: _imageKey,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              )
            : _uploading
                ? const CircularProgressIndicator(color: kPurple700)
                : Column(
                    children: const [
                      Icon(Icons.add_a_photo_outlined, size: 42, color: kPurple700),
                      SizedBox(height: 10),
                      Text(
                        'Take a photo or choose an image',
                        style: TextStyle(fontSize: 14, color: kGray),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, String hint,
      {bool req = false, bool number = false, bool decimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kTitle,
              ),
            ),
            if (req)
              const Text(' *', style: TextStyle(color: kRed, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : number
                  ? TextInputType.number
                  : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kGray, fontSize: 14),
            filled: true,
            fillColor: kBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
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
            onTap: _saving ? null : _submit,
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
                  : const Text(
                      'Add Product',
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