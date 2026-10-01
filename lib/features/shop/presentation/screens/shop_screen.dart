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
import 'package:posfrontend/shared/widgets/wizard_step_indicator.dart';

/// Layout thresholds, matching the other screens so they all agree on what
/// "wide" means.
///
/// This form was authored for a portrait phone, where one card of stacked
/// fields is the only sane arrangement. Left alone on a desktop window it
/// stretches the inputs to a 1900pt line and leaves the logo picker sitting on
/// top of them like a banner. So past [twoPaneFrom] the image moves into its own
/// column beside the fields, and the whole column is capped at [contentMaxWidth]
/// so it never becomes a form with a search bar's worth of whitespace.
class _ShopLayout {
  _ShopLayout._();

  /// Width at which the image gets its own column. The same 768 the product,
  /// inventory and sale screens use, so the app flips to two panes in the same
  /// places rather than per-screen.
  static const double twoPaneFrom = 768;

  /// Ceiling on the form column. Wider than login's 440 and register's 720
  /// because this form has paired fields in the owner step and an image column
  /// beside the shop step.
  static const double contentMaxWidth = 960;

  /// Cap on the action row, which sits below the form rather than inside it.
  static const double actionsMaxWidth = 640;

  /// Gap between the image column and the fields column.
  static const double paneGap = 24;

  /// Horizontal page padding, which grows once there is room for it.
  static const double gutter = 20;
  static const double wideGutter = 32;

  /// Cap on how tall the logo picker grows before it starts looking like a
  /// hero image. On a desktop window an unbounded upload box would take the
  /// whole viewport height and push the fields below the fold.
  static const double imageMaxHeight = 260;

  static double gutterFor(double width) =>
      width >= twoPaneFrom ? wideGutter : gutter;
}

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

  /// Which half of the wizard is showing. Only meaningful in `create` mode.
  int _step = 0;

  static const int _stepCount = 2;

  bool get _isFirstStep => _step == 0;
  bool get _isLastStep => _step == _stepCount - 1;

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
    setState(() => _step = 0);
    _viewModel.reset();
  }

  /// Gates the move to step 2 on step 1's fields only, so the user is told what
  /// is missing before the page changes rather than after.
  void _goToNextStep() {
    if (!_viewModel.validateShopStep()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  void _goToPreviousStep() {
    FocusScope.of(context).unfocus();
    setState(() => _step = 0);
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
            // Painted behind the scroll view so the bottom of the page, past the
            // last field and under the action buttons, is the same colour on
            // every step and the same colour as the register screen behind it.
            backgroundColor: p.scaffoldBg,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isWide = width >= _ShopLayout.twoPaneFrom;
                  final gutter = _ShopLayout.gutterFor(width);
                  return Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: RefreshableBody(
                          onRefresh: _refresh,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _ShopLayout.contentMaxWidth,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: gutter,
                                  vertical: 20,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(child: _buildModeToggle()),
                                      const SizedBox(height: 16),
                                      if (_viewModel.mode == 'existing') ...[
                                        _buildExistingShopPicker(),
                                        const SizedBox(height: 32),
                                        _buildFullWidthActions(
                                          GradientButton(
                                            label: context.l10n.t('Continue'),
                                            icon: Icons.arrow_forward,
                                            loading:
                                                _viewModel.isLoading ||
                                                _viewModel.isLoadingShops,
                                            onPressed: _onUseExistingShop,
                                          ),
                                        ),
                                      ] else ...[
                                        _buildStepIndicator(),
                                        const SizedBox(height: 20),
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          child: KeyedSubtree(
                                            key: ValueKey(_step),
                                            child: _isFirstStep
                                                ? _buildShopInfoStep(
                                                    errors,
                                                    isWide: isWide,
                                                  )
                                                : _buildOwnerInfoStep(
                                                    errors,
                                                    isWide: isWide,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        _buildWizardActions(),
                                      ],
                                      if (_viewModel.errorMessage != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
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
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final p = context.palette;
    final wide = MediaQuery.of(context).size.width >= _ShopLayout.twoPaneFrom;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: wide ? 20 : 18,
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

  /// Two numbered pills joined by a rule that fills in as the wizard advances.
  ///
  /// Delegated to the shared indicator so this and the register wizard cannot
  /// drift apart in colour or in when they drop the labels.
  Widget _buildStepIndicator() {
    return WizardStepIndicator(
      labels: const ['Shop Info', 'Owner Info'],
      currentIndex: _step,
    );
  }

  Widget _buildShopInfoStep(
    Map<String, String?> errors, {
    required bool isWide,
  }) {
    // On a wide window the image gets its own column. It is a square, so
    // without a cap it grows with the window and pushes the fields down.
    final image = _buildImageUpload();

    final fields = [
      RequiredLabel('Shop Name'),
      TextFormField(
        controller: _shopNameController,
        textInputAction: TextInputAction.next,
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
        isExpanded: true,
        decoration:
            appInputDecoration(
              context,
              icon: Icons.category_outlined,
              hint: context.l10n.t('Select type'),
              errorText: errors['type'],
            ).copyWith(
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.primary,
              ),
            ),
        items: ShopTypes.values
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (value) => _viewModel.setType(value),
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
          hint: context.l10n.t('Enter physical address'),
          errorText: errors['physicalAddress'],
        ),
      ),
    ];

    return _sectionTile(
      context,
      'Shop Info',
      isWide
          ? [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(flex: 4, child: image),
                    const SizedBox(width: _ShopLayout.paneGap),
                    Flexible(flex: 6, child: Column(children: fields)),
                  ],
                ),
              ),
            ]
          : [image, const SizedBox(height: 20), ...fields],
    );
  }

  Widget _buildOwnerInfoStep(
    Map<String, String?> errors, {
    required bool isWide,
  }) {
    final name = [
      RequiredLabel("Owner's Name"),
      TextFormField(
        controller: _ownerNameController,
        textInputAction: TextInputAction.next,
        decoration: appInputDecoration(
          context,
          icon: Icons.person_outline,
          hint: "Enter owner's name",
          errorText: errors['ownerName'],
        ),
      ),
    ];

    final email = [
      RequiredLabel("Owner's Email"),
      TextFormField(
        controller: _ownerEmailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: appInputDecoration(
          context,
          icon: Icons.email_outlined,
          hint: "Enter owner's email",
          errorText: errors['ownerEmail'],
        ),
      ),
    ];

    final phone = [
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
    ];

    // Phone sits next to email on a wide window; name stays full width above
    // both because a name has no useful width limit and splitting it would buy
    // nothing.
    final children = isWide
        ? [
            ...name,
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: Column(children: email)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: Column(children: phone)),
              ],
            ),
          ]
        : [
            ...name,
            const SizedBox(height: 16),
            ...email,
            const SizedBox(height: 16),
            ...phone,
          ];

    return _sectionTile(context, 'Owner Info', children);
  }

  /// Back on step 1, Next on step 2. Both rows keep the primary action full
  /// width so the button does not jump side as the user moves through the flow.
  Widget _buildWizardActions() {
    final back = _outlineButton(
      icon: Icons.arrow_back,
      label: context.l10n.t('Back'),
      onPressed: _goToPreviousStep,
    );

    if (!_isLastStep) {
      return _buildFullWidthActions(
        Row(
          children: [
            Expanded(child: back),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GradientButton(
                label: context.l10n.t('Next'),
                icon: Icons.arrow_forward,
                onPressed: _goToNextStep,
              ),
            ),
          ],
        ),
      );
    }

    return _buildFullWidthActions(
      Row(
        children: [
          Expanded(child: back),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GradientButton(
              label: context.l10n.t('Create Shop'),
              icon: Icons.save_outlined,
              loading: _viewModel.isLoading,
              onPressed: _onCreateShop,
            ),
          ),
        ],
      ),
    );
  }

  /// Caps an action row and centres it.
  ///
  /// Without the cap a two-button row on a desktop window becomes two very
  /// wide buttons with a long gap between them, which reads as unrelated rather
  /// than as a pair.
  Widget _buildFullWidthActions(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _ShopLayout.actionsMaxWidth,
        ),
        child: child,
      ),
    );
  }

  /// The secondary action. Outlined rather than flat so it reads as available
  /// but secondary next to the gradient primary.
  Widget _outlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final p = context.palette;
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: p.textSecondary),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: p.textSecondary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: p.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
          height: _ShopLayout.imageMaxHeight,
        ),
        SizedBox(height: 10),
        _helperText(context, 'Recommended 1:1 · JPG or PNG up to 5MB'),
      ],
    );
  }

  Widget _buildModeToggle() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: 'create',
            label: Text(
              context.l10n.t('Create Shop?'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ButtonSegment(
            value: 'existing',
            label: Text(
              context.l10n.t('Link Shop?'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        selected: {_viewModel.mode},
        onSelectionChanged: (selected) => _viewModel.setMode(selected.first),
        style: const ButtonStyle(visualDensity: VisualDensity.comfortable),
      ),
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
    // The cap has to be a whole number of rows. An arbitrary 320 against 72pt
    // rows plus 10pt gaps puts the fourth row at 318, so a sliver of the next
    // row lands on the boundary and the grid reports a bottom overflow by a
    // pixel. Four whole rows is 4 * (76 + 10) - 10.
    final rows = 4;
    final rowExtent = 76.0;
    final rowGap = 10.0;
    final maxHeight = rows * rowExtent + (rows - 1) * rowGap;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Two columns once a single result is wide enough to read on its own.
          // A one-column list on a desktop window leaves the right half of the
          // page empty and makes the user scan further per result.
          final columns = constraints.maxWidth >= 560 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: _viewModel.shops.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: rowGap,
              crossAxisSpacing: rowGap,
              // Room for the avatar and two lines of text without the second
              // line clipping against the tile's own bottom padding.
              mainAxisExtent: rowExtent,
            ),
            itemBuilder: (context, index) {
              final shop = _viewModel.shops[index];
              final selected = _viewModel.selectedOldShop?.id == shop.id;
              return _shopResultTile(context, shop, selected);
            },
          );
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
