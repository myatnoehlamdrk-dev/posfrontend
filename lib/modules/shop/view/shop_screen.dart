import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/modules/auth/view/register_screen.dart';
import 'package:posfrontend/modules/shop/model/shop_types.dart';
import 'package:posfrontend/modules/shop/repository/shop_local_repository_impl.dart';
import 'package:posfrontend/modules/shop/viewmodel/shop_view_model.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final ShopViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  static const Color primary = Color(0xFF7B2CBF);
  static const Color primaryLight = Color(0xFF9D4EDD);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color labelColor = Color(0xFF1A1A1A);
  static const Color hintColor = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _viewModel = ShopViewModel(repository: ShopLocalRepositoryImpl());
    _viewModel.loadSavedShop().then((_) {
      _shopNameController.text = _viewModel.name;
      _addressController.text = _viewModel.physicalAddress;
      _ownerNameController.text = _viewModel.ownerName;
      _ownerEmailController.text = _viewModel.ownerEmail;
      _ownerPhoneController.text = _viewModel.ownerPhone;
      if (mounted) setState(() {});
    });

    _shopNameController.addListener(() => _viewModel.setName(_shopNameController.text));
    _addressController.addListener(
        () => _viewModel.setPhysicalAddress(_addressController.text));
    _ownerNameController.addListener(() => _viewModel.setOwnerName(_ownerNameController.text));
    _ownerEmailController.addListener(
        () => _viewModel.setOwnerEmail(_ownerEmailController.text));
    _ownerPhoneController.addListener(
        () => _viewModel.setOwnerPhone(_ownerPhoneController.text));
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      _viewModel.setLogo(base64Encode(bytes));
    }
  }

  Future<void> _onCreateShop() async {
    final success = await _viewModel.createShop();
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    }
  }

  InputDecoration _inputDecoration({
    required IconData icon,
    required String hint,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      hintStyle: const TextStyle(color: hintColor, fontSize: 14),
      prefixIcon: Icon(icon, color: primary, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _requiredLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(color: hintColor, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final errors = _viewModel.fieldErrors;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageUpload(),
                          const SizedBox(height: 20),
                          _requiredLabel('Shop Name'),
                          TextFormField(
                            controller: _shopNameController,
                            decoration: _inputDecoration(
                              icon: Icons.store_outlined,
                              hint: 'Enter shop name',
                              errorText: errors['name'],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _requiredLabel('Type'),
                          DropdownButtonFormField<String>(
                            value: _viewModel.type,
                            decoration: _inputDecoration(
                              icon: Icons.category_outlined,
                              hint: 'Select type',
                              errorText: errors['type'],
                            ).copyWith(
                              suffixIcon: const Icon(
                                Icons.arrow_drop_down,
                                color: primary,
                              ),
                            ),
                            items: ShopTypes.values
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => _viewModel.setType(value),
                          ),
                          _helperText(
                            'Allowed types: Shop, Services Center, Store, and Restaurants',
                          ),
                          const SizedBox(height: 20),
                          _requiredLabel('Physical Address'),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              icon: Icons.location_on_outlined,
                              hint: 'Enter physical address',
                              errorText: errors['physicalAddress'],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Owner Information',
                            style: TextStyle(
                              color: primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _requiredLabel("Owner's Name"),
                          TextFormField(
                            controller: _ownerNameController,
                            decoration: _inputDecoration(
                              icon: Icons.person_outline,
                              hint: "Enter owner's name",
                              errorText: errors['ownerName'],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _requiredLabel("Owner's Email"),
                          TextFormField(
                            controller: _ownerEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              icon: Icons.email_outlined,
                              hint: "Enter owner's email",
                              errorText: errors['ownerEmail'],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _requiredLabel("Owner's Phone"),
                          TextFormField(
                            controller: _ownerPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              icon: Icons.phone_outlined,
                              hint: "Enter owner's phone number",
                              errorText: errors['ownerPhone'],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
                          if (_viewModel.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _viewModel.errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: const Center(
        child: Text(
          'Create Shop',
          style: TextStyle(
            color: labelColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    final logoData = _viewModel.logoData;
    final hasImage = logoData != null && logoData.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requiredLabel('Shop Image (optional)'),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F0FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: primary,
                  radius: 16,
                  strokeWidth: 1.5,
                  dashWidth: 8,
                  dashSpace: 6,
                ),
                child: hasImage
                    ? Image.memory(
                        base64Decode(logoData),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo_outlined,
                              color: primary,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tap to upload shop image',
                              style: TextStyle(
                                color: primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'JPG, PNG up to 5MB',
                              style: TextStyle(color: hintColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final loading = _viewModel.isLoading;
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : _onCreateShop,
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Create Shop',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.dashWidth = 8,
    this.dashSpace = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
