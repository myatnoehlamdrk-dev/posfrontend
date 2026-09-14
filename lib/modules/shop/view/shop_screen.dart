import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/modules/register/view/register_screen.dart';
import 'package:posfrontend/modules/shop/model/shop.dart';
import 'package:posfrontend/modules/shop/model/shop_types.dart';
import 'package:posfrontend/modules/shop/repository/shop_api_repository_impl.dart';
import 'package:posfrontend/modules/shop/repository/shop_local_repository_impl.dart';
import 'package:posfrontend/modules/shop/viewmodel/shop_view_model.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/required_label.dart';

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

  @override
  void initState() {
    super.initState();
    _viewModel = ShopViewModel(
      repository: ShopLocalRepositoryImpl(),
      apiRepository: ShopApiRepositoryImpl(),
    );
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
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    if (!mounted) return;
    _viewModel.setLogo(base64Encode(bytes));
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

  Widget _helperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(color: AppColors.hintColor, fontSize: 12),
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
                          _buildModeToggle(),
                          const SizedBox(height: 16),
                          if (_viewModel.mode == 'existing') ...[
                            _buildExistingShopPicker(),
                            const SizedBox(height: 32),
                            GradientButton(
                              label: 'Continue',
                              icon: Icons.arrow_forward,
                              loading: _viewModel.isLoading || _viewModel.isLoadingShops,
                              onPressed: _onUseExistingShop,
                            ),
                          ] else ...[
                            _buildImageUpload(),
                            const SizedBox(height: 20),
                            RequiredLabel('Shop Name'),
                            TextFormField(
                              controller: _shopNameController,
                              decoration: appInputDecoration(
                                icon: Icons.store_outlined,
                                hint: 'Enter shop name',
                                errorText: errors['name'],
                              ),
                            ),
                            const SizedBox(height: 20),
                            RequiredLabel('Type'),
                            DropdownButtonFormField<String>(
                              initialValue: _viewModel.type,
                              decoration: appInputDecoration(
                                icon: Icons.category_outlined,
                                hint: 'Select type',
                                errorText: errors['type'],
                              ).copyWith(
                                suffixIcon: Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.primary,
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
                            RequiredLabel('Physical Address'),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 3,
                              decoration: appInputDecoration(
                                icon: Icons.location_on_outlined,
                                hint: 'Enter physical address',
                                errorText: errors['physicalAddress'],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Owner Information',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RequiredLabel("Owner's Name"),
                            TextFormField(
                              controller: _ownerNameController,
                              decoration: appInputDecoration(
                                icon: Icons.person_outline,
                                hint: "Enter owner's name",
                                errorText: errors['ownerName'],
                              ),
                            ),
                            const SizedBox(height: 20),
                            RequiredLabel("Owner's Email"),
                            TextFormField(
                              controller: _ownerEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: appInputDecoration(
                                icon: Icons.email_outlined,
                                hint: "Enter owner's email",
                                errorText: errors['ownerEmail'],
                              ),
                            ),
                            const SizedBox(height: 20),
                            RequiredLabel("Owner's Phone"),
                            TextFormField(
                              controller: _ownerPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: appInputDecoration(
                                icon: Icons.phone_outlined,
                                hint: "Enter owner's phone number",
                                errorText: errors['ownerPhone'],
                              ),
                            ),
                            const SizedBox(height: 32),
                            GradientButton(
                              label: 'Create Shop',
                              icon: Icons.save_outlined,
                              loading: _viewModel.isLoading || _viewModel.isLoadingShops,
                              onPressed: _onCreateShop,
                            ),
                          ],
                          if (_viewModel.errorMessage != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  _viewModel.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                )),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: AppColors.primary),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Center(
              child: Text(
                'Create Shop',
                style: TextStyle(
                  color: AppColors.labelColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildImageUpload() {
    final logoData = _viewModel.logoData;
    final logoUrl = _viewModel.logoUrl;
    final hasImage = (logoData != null && logoData.isNotEmpty) ||
        (logoUrl != null && logoUrl.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequiredLabel('Shop Image (optional)'),
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
                  color: AppColors.primary,
                  radius: 16,
                  strokeWidth: 1.5,
                  dashWidth: 8,
                  dashSpace: 6,
                ),
                child: hasImage
                    ? (logoUrl != null && logoUrl.isNotEmpty
                        ? Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Image.memory(
                            base64Decode(logoData!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ))
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.primary,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to upload shop image',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'JPG, PNG up to 5MB',
                              style: TextStyle(color: AppColors.hintColor, fontSize: 12),
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

  Widget _buildModeToggle() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'create',
          label: Text('Create new shop'),
        ),
        ButtonSegment(
          value: 'existing',
          label: Text('Use existing shop'),
        ),
      ],
      selected: {_viewModel.mode},
      onSelectionChanged: (selected) => _viewModel.setMode(selected.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.comfortable,
      ),
    );
  }

  Widget _buildExistingShopPicker() {
    if (_viewModel.isLoadingShops) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_viewModel.shops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No shops found in the database.',
          style: TextStyle(color: AppColors.hintColor, fontSize: 14),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequiredLabel('Select Shop'),
        DropdownButtonFormField<Shop>(
          initialValue: _viewModel.selectedShop,
          decoration: appInputDecoration(
            icon: Icons.store_outlined,
            hint: 'Choose your shop',
          ),
          items: _viewModel.shops
              .map(
                (shop) => DropdownMenuItem(
                  value: shop,
                  child: Text(shop.name),
                ),
              )
              .toList(),
          onChanged: (shop) {
            if (shop != null) _viewModel.selectExistingShop(shop);
          },
        ),
      ],
    );
  }

  Future<void> _onUseExistingShop() async {
    if (_viewModel.selectedShop == null) {
      _viewModel.setError('Please select a shop to continue.');
      return;
    }
    await _viewModel.saveSelectedShop();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    }
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
