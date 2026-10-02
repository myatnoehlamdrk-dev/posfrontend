import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/features/product/data/models/product_create_models.dart';
import 'package:posfrontend/features/product/data/repositories/product_create_repository_impl.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/shared/widgets/premium_image_upload.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

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

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final p = ctx.palette;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
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
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _sheetOption(
    BuildContext ctx,
    IconData icon,
    String label,
    ImageSource source,
  ) {
    final p = ctx.palette;
    return ListTile(
      leading: Icon(icon, color: AppColors.brandPurple),
      title: Text(label, style: TextStyle(fontSize: 15, color: p.textPrimary)),
      onTap: () => Navigator.pop(ctx, source),
    );
  }

  Future<void> _submit() async {
    if (_uploading) {
      showErrorMessage(
        context,
        context.l10n.t('Please wait for image upload to finish'),
      );
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      showErrorMessage(context, context.l10n.t('Product name is required'));
      return;
    }
    final stock = int.tryParse(_stock.text.trim());
    if (stock == null || stock < 0) {
      showErrorMessage(context, context.l10n.t('Enter a valid stock amount'));
      return;
    }
    final price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) {
      showErrorMessage(context, context.l10n.t('Enter a valid price'));
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository.createProduct(
        ProductCreateRequest(
          name: name,
          imageUrl: _imageUrl ?? '',
          stock: stock,
          variants: [ProductCreateVariant(quantity: stock, price: price)],
          imageDeleteUrl: _imageDeleteUrl ?? '',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      showErrorMessage(context, e.message);
    } catch (e) {
      showErrorMessage(context, context.l10n.t('Failed to add product'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t('Quick Add Product'),
              showMenuButton: false,
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormCard(
                      label: context.l10n.t('Product Image'),
                      helper: context.l10n.t(
                        'Take a photo or upload an image.',
                      ),
                      child: _imageSection(),
                    ),
                    const SizedBox(height: 16),
                    FormCard(
                      label: context.l10n.t('Basic Info'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field(
                            'Product Name',
                            _name,
                            'e.g. Wireless Headphones Pro',
                            req: true,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            'Stock',
                            _stock,
                            'e.g. 50',
                            req: true,
                            number: true,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            'Price',
                            _price,
                            'e.g. 25000',
                            req: true,
                            number: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _submitButton(),
    );
  }

  Widget _imageSection() {
    final file = _imageFile;
    return PremiumImageUpload(
      isBusy: _uploading,
      onTap: _uploading ? null : _pickImage,
      height: 168,
      icon: Icons.add_a_photo_outlined,
      title: context.l10n.t('Product image'),
      subtitle: context.l10n.t('Take a photo or choose an image'),
      hint: context.l10n.t('JPG or PNG up to 5MB'),
      changeLabel: context.l10n.t('Change photo'),
      image: file == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(
                      file.path,
                      key: _imageKey,
                      height: 168,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      file,
                      key: _imageKey,
                      height: 168,
                      fit: BoxFit.cover,
                    ),
            ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c,
    String hint, {
    bool req = false,
    bool number = false,
    bool decimal = false,
  }) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: p.textPrimary,
              ),
            ),
            if (req) Text(' *', style: TextStyle(color: kRed, fontSize: 14)),
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
            hintStyle: TextStyle(color: p.textSecondary, fontSize: 14),
            filled: true,
            fillColor: p.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
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
                  : Text(
                      context.l10n.t('Add Product'),
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
