import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/features/auth/presentation/screens/register_screen.dart';
import 'package:posfrontend/features/shop/presentation/viewmodels/shop_view_model.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart'
    as old_shop;
import 'package:posfrontend/features/shop/domain/entities/shop_types.dart';
import 'package:posfrontend/features/shop/data/repositories/shop_api_repository_impl.dart';
import 'package:posfrontend/features/shop/data/repositories/shop_local_repository_impl.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_input_decoration.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/shared/widgets/premium_image_upload.dart';
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
  final _shopSearchController = TextEditingController();
  String _searchQuery = '';
  String _searchedQuery = '';

  @override
  void initState() {
    super.initState();
    _viewModel = ShopViewModel(
      localRepository: ShopLocalRepositoryImpl(),
      apiRepository: ShopApiRepositoryImpl(),
    );

    _shopNameController.addListener(
      () => _viewModel.setName(_shopNameController.text),
    );
    _addressController.addListener(
      () => _viewModel.setPhysicalAddress(_addressController.text),
    );
    _ownerNameController.addListener(
      () => _viewModel.setOwnerName(_ownerNameController.text),
    );
    _ownerEmailController.addListener(
      () => _viewModel.setOwnerEmail(_ownerEmailController.text),
    );
    _ownerPhoneController.addListener(
      () => _viewModel.setOwnerPhone(_ownerPhoneController.text),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _shopSearchController.dispose();
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

  void _resetForm() {
    _shopNameController.clear();
    _addressController.clear();
    _ownerNameController.clear();
    _ownerEmailController.clear();
    _ownerPhoneController.clear();
    _shopSearchController.clear();
    _searchQuery = '';
    _searchedQuery = '';
    _viewModel.reset();
  }

  Future<void> _onCreateShop() async {
    final success = await _viewModel.createShop();
    if (success && mounted) {
      _resetForm();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    }
  }

  Widget _helperText(BuildContext context, String text) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: TextStyle(color: p.textMuted, fontSize: 12)),
    );
  }

  Widget _sectionHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTile(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_sectionHeading(title), ...children],
      ),
    );
  }

  Future<void> _refresh() {
    if (_viewModel.mode == 'existing') {
      final query = _searchedQuery;
      return _viewModel.loadShops(query: query.isEmpty ? null : query);
    }
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final p = context.palette;
        final errors = _viewModel.fieldErrors;
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) _viewModel.reset();
          },
          child: Scaffold(
            backgroundColor: p.scaffoldBg,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: RefreshableBody(
                      onRefresh: _refresh,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: _buildModeToggle()),
                              const SizedBox(height: 16),
                              if (_viewModel.mode == 'existing') ...[
                                _buildExistingShopPicker(),
                                const SizedBox(height: 32),
                                GradientButton(
                                  label: context.l10n.t('Continue'),
                                  icon: Icons.arrow_forward,
                                  loading:
                                      _viewModel.isLoading ||
                                      _viewModel.isLoadingShops,
                                  onPressed: _onUseExistingShop,
                                ),
                              ] else ...[
                                _sectionTile(context, 'Shop Info', [
                                  _buildImageUpload(),
                                  const SizedBox(height: 20),
                                  RequiredLabel('Shop Name'),
                                  TextFormField(
                                    controller: _shopNameController,
                                    decoration: appInputDecoration(
                                      context,
                                      icon: Icons.store_outlined,
                                      hint: context.l10n.t('Enter shop name'),
                                      errorText: errors['name'],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  RequiredLabel('Type'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _viewModel.type,
                                    decoration:
                                        appInputDecoration(
                                          context,
                                          icon: Icons.category_outlined,
                                          hint: context.l10n.t('Select type'),
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
                                    onChanged: (value) =>
                                        _viewModel.setType(value),
                                  ),
                                  _helperText(
                                    context,
                                    'Allowed types: Shop, Services Center, Store, and Restaurants',
                                  ),
                                  const SizedBox(height: 16),
                                  RequiredLabel('Physical Address'),
                                  TextFormField(
                                    controller: _addressController,
                                    maxLines: 3,
                                    decoration: appInputDecoration(
                                      context,
                                      icon: Icons.location_on_outlined,
                                      hint: context.l10n.t(
                                        'Enter physical address',
                                      ),
                                      errorText: errors['physicalAddress'],
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 24),
                                _sectionTile(context, 'Owner Info', [
                                  RequiredLabel("Owner's Name"),
                                  TextFormField(
                                    controller: _ownerNameController,
                                    decoration: appInputDecoration(
                                      context,
                                      icon: Icons.person_outline,
                                      hint: "Enter owner's name",
                                      errorText: errors['ownerName'],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  RequiredLabel("Owner's Email"),
                                  TextFormField(
                                    controller: _ownerEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: appInputDecoration(
                                      context,
                                      icon: Icons.email_outlined,
                                      hint: "Enter owner's email",
                                      errorText: errors['ownerEmail'],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  RequiredLabel("Owner's Phone"),
                                  TextFormField(
                                    controller: _ownerPhoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: appInputDecoration(
                                      context,
                                      icon: Icons.phone_outlined,
                                      hint: "Enter owner's phone number",
                                      errorText: errors['ownerPhone'],
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 28),
                                GradientButton(
                                  label: context.l10n.t('Create Shop'),
                                  icon: Icons.save_outlined,
                                  loading:
                                      _viewModel.isLoading ||
                                      _viewModel.isLoadingShops,
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
                                  ),
                                ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border, width: 1)),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            const CustomBackButton()
          else
            const SizedBox(width: 48),
          Expanded(
            child: Center(
              child: Text(
                context.l10n.t('Create Shop'),
                style: TextStyle(
                  color: p.textPrimary,
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
    final p = context.palette;
    final logoData = _viewModel.logoData;
    final logoUrl = _viewModel.logoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.t('Shop Image'),
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        PremiumImageUpload(
          onTap: _pickImage,
          imageUrl: logoUrl,
          imageBase64: logoData,
          title: context.l10n.t('Upload shop image'),
          subtitle: context.l10n.t('Tap to browse your gallery'),
          hint: context.l10n.t('JPG or PNG · up to 5MB'),
          changeLabel: context.l10n.t('Change photo'),
        ),
        SizedBox(height: 10),
        _helperText(context, 'Recommended 1:1 · JPG or PNG up to 5MB'),
      ],
    );
  }

  Widget _buildModeToggle() {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'create',
          label: Text(context.l10n.t('Create Shop?')),
        ),
        ButtonSegment(
          value: 'existing',
          label: Text(context.l10n.t('Link Shop?')),
        ),
      ],
      selected: {_viewModel.mode},
      onSelectionChanged: (selected) => _viewModel.setMode(selected.first),
      style: const ButtonStyle(visualDensity: VisualDensity.comfortable),
    );
  }

  void _performSearch() {
    final query = _searchQuery;
    if (query.isEmpty) return;
    _searchedQuery = query;
    _viewModel.loadShops(query: query);
  }

  void _clearSearch() {
    _shopSearchController.clear();
    _searchedQuery = '';
    _searchQuery = '';
    _viewModel.clearShops();
  }

  Widget _buildExistingShopPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _shopSearchController,
          textInputAction: TextInputAction.search,
          decoration: appInputDecoration(
            context,
            icon: Icons.search,
            hint: context.l10n.t('Search shop by name, address or owner'),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear search',
                    onPressed: _clearSearch,
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Search',
                  onPressed: _performSearch,
                ),
              ],
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value.trim()),
          onSubmitted: (_) => _performSearch(),
        ),
        const SizedBox(height: 16),
        _buildSearchBody(context),
      ],
    );
  }

  Widget _buildSearchBody(BuildContext context) {
    if (_searchedQuery.isEmpty) {
      return _searchHint(
        context,
        'Type above, then press the search button to find your shop.',
      );
    }
    if (_viewModel.isLoadingShops && _viewModel.shops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_viewModel.shops.isEmpty) {
      return _searchHint(context, 'No shops match your search.');
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: _viewModel.shops.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final shop = _viewModel.shops[index];
          final selected = _viewModel.selectedOldShop?.id == shop.id;
          return _shopResultTile(context, shop, selected);
        },
      ),
    );
  }

  Widget _searchHint(BuildContext context, String text) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: TextStyle(color: p.textMuted, fontSize: 14)),
    );
  }

  Widget _shopResultTile(
    BuildContext context,
    old_shop.Shop shop,
    bool selected,
  ) {
    final p = context.palette;
    return GestureDetector(
      onTap: () => _viewModel.selectExistingShop(shop),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? p.selectionTint : p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : p.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: p.chipBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.store_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: p.textPrimary,
                    ),
                  ),
                  if (shop.physicalAddress.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      shop.physicalAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textMuted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onUseExistingShop() async {
    if (_viewModel.selectedOldShop == null) {
      _viewModel.setError('Please select a shop to continue.');
      return;
    }
    await _viewModel.saveSelectedShop();
    if (mounted) {
      _resetForm();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    }
  }
}
