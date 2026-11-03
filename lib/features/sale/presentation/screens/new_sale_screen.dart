import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:flutter/services.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/features/cart/data/cart_store.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_repository_impl.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_product_repository_impl.dart';
import 'package:posfrontend/features/sale/presentation/screens/sale_preview_screen.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/sale_view_model.dart';
import 'package:posfrontend/features/sale/presentation/widgets/bluetooth_printer_picker.dart';
import 'package:posfrontend/features/sale/presentation/widgets/percent_input_formatter.dart';
import 'package:posfrontend/features/settings/domain/entities/printer_profile.dart';
import 'package:posfrontend/shared/services/bluetooth_printer_candidate.dart';
import 'package:posfrontend/shared/services/receipt_print_service.dart';
import 'package:posfrontend/shared/services/sale_output_service.dart';
import 'package:posfrontend/shared/services/thermal_printer_transport.dart';
import 'package:posfrontend/shared/services/usb_printer_candidate.dart';
import 'package:posfrontend/shared/services/usb_printer_transport.dart';
import 'package:posfrontend/shared/services/usb_setup_download.dart';
import 'package:posfrontend/features/sale/presentation/screens/sale_items_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/totals_panel.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart'
    show navigateToDashboard;
import 'package:posfrontend/shared/widgets/cached_product_image.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class NewSaleScreen extends StatefulWidget {
  final List<SaleItemEntity>? initialItems;
  final String? initialCustomerName;
  final String? initialCustomerPhone;
  final String? initialPaymentMethod;
  final String? existingOrderId;
  const NewSaleScreen({
    super.key,
    this.initialItems,
    this.initialCustomerName,
    this.initialCustomerPhone,
    this.initialPaymentMethod,
    this.existingOrderId,
  });

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  AppPalette get _p => context.palette;
  Color get _titleColor => _p.textPrimary;
  Color get _mutedColor => _p.textSecondary;

  /// The one purple the whole app's actions are painted in, and the same one
  /// the welcome screen's `Get started` button uses. It replaces the theme's
  /// own violet here so selecting a payment method, toggling a switch and
  /// saving the sale all read as the same accent as the rest of the product.
  Color get _accentColor => AppColors.brandPurple;
  Color get _borderColor => _p.border;

  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _customerNameCtrl = TextEditingController(
    text: 'Customer',
  );
  final TextEditingController _customerPhoneCtrl = TextEditingController();
  final TextEditingController _customerLocationCtrl = TextEditingController();
  late final SaleViewModel _viewModel;

  /// The one output choice both sale surfaces read, mirrored into local
  /// state so the sheet can edit it without awaiting prefs on every tap.
  String _output = SalePrintSettings.outputPdf;
  String _paperSize = '58mm';
  String _btPrinterAddress = '';
  String _btPrinterName = '';
  PrinterProfile? _wifiPrinter;
  UsbPrinterCandidate? _usbPrinter;

  @override
  void initState() {
    super.initState();
    _viewModel = SaleViewModel(
      productRepository: SaleProductRepositoryImpl(),
      saleRepository: SaleRepositoryImpl(),
      orderRepository: OrderRepositoryImpl(),
      customerRepository: CustomerRepositoryImpl(),
    );
    _viewModel.init(
      initialItems: widget.initialItems,
      initialCustomerName: widget.initialCustomerName,
      initialCustomerPhone: widget.initialCustomerPhone,
      initialPaymentMethod: widget.initialPaymentMethod,
    );
    _customerNameCtrl.text = _viewModel.customerName;
    if (widget.initialCustomerPhone != null) {
      _customerPhoneCtrl.text = widget.initialCustomerPhone!;
    }
    _loadPrintSettings();
  }

  Future<void> _loadPrintSettings() async {
    final settings = await SalePrintSettings.load();
    final printer = await SaleOutputService.defaultNetworkPrinter();
    final usb = UsbPrinterTransport.isSupported
        ? await UsbPrinterTransport.loadSelected()
        : null;
    if (!mounted) return;
    setState(() {
      _output = settings.output;
      _paperSize = settings.paperSize;
      _btPrinterAddress = settings.btPrinterAddress;
      _btPrinterName = settings.btPrinterName;
      _wifiPrinter = printer;
      _usbPrinter = usb;
    });
  }

  /// Persists everything the sheet holds. The keys live in
  /// [SalePrintSettings] alone — the sheet used to carry its own copies of
  /// them, which is exactly how the two surfaces drifted apart before.
  Future<void> _savePrintSettings() async {
    await SalePrintSettings.setOutput(_output);
    await SalePrintSettings.setPaperSize(_paperSize);
    await SalePrintSettings.setBluetoothPrinter(
      address: _btPrinterAddress,
      name: _btPrinterName,
    );
  }

  Future<void> _submitSale() async {
    final staffName = AuthScope.userOf(context)?.fullName ?? 'Staff';
    _viewModel.setCustomerName(_customerNameCtrl.text);
    _viewModel.setCustomerPhone(_customerPhoneCtrl.text);
    _viewModel.setCustomerLocation(_customerLocationCtrl.text);
    final success = await _viewModel.submitSale(
      staffName: staffName,
      existingOrderId: widget.existingOrderId,
    );
    if (!success) {
      if (!mounted) return;
      showErrorSnackBar(
        context,
        Exception(_viewModel.errorMessage ?? 'Failed to save sale'),
      );
      return;
    }
    if (!mounted) return;

    final itemsSnapshot = List<SaleItemEntity>.from(_viewModel.items);
    final customerName = _customerNameCtrl.text;
    final customerPhone = _customerPhoneCtrl.text.isNotEmpty
        ? _customerPhoneCtrl.text
        : null;
    final customerLocation = _customerLocationCtrl.text.isNotEmpty
        ? _customerLocationCtrl.text
        : null;
    final paymentMethod = _viewModel.paymentMethod;
    final notes = _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null;
    final voucherNo = 'INV-${_viewModel.voucherRandom}';
    final orderId = widget.existingOrderId ?? 'ORD-${_viewModel.orderRandom}';
    final shop = ShopScope.shopOf(context);
    final saleArgs = ReceiptPrintService.buildArgs(
      customerName: customerName,
      customerPhone: customerPhone,
      customerLocation: customerLocation,
      staffName: staffName,
      voucherNo: voucherNo,
      orderId: orderId,
      items: itemsSnapshot,
      discountPct: _viewModel.discountPercent,
      subtotal: _viewModel.subtotal,
      discountAmt: _viewModel.discountAmount,
      totalPayable: _viewModel.totalPayable,
      paymentMethod: paymentMethod,
      notes: notes,
      shopName: shop?.name,
      shopAddress: shop?.physicalAddress,
      shopPhone: shop?.ownerInformation.phone,
      shopImage: shop?.logoUrl ?? shop?.logoData,
    );

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _customerNameCtrl.text = 'Customer';
      _customerPhoneCtrl.clear();
      _customerLocationCtrl.clear();
      _discountCtrl.text = '0';
      _notesCtrl.clear();
    });
    _viewModel.clearCart();

    if (widget.existingOrderId != null) {
      final draft = CartStore.instance.value
          .where((c) => c.orderId == widget.existingOrderId)
          .toList();
      for (final card in draft) {
        await CartStore.instance.removeCard(card.id);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && messenger.mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const AppMessageBanner(
                message: 'Sale saved successfully!',
                kind: AppMessageKind.success,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
      }
      // The output runs *after* the success banner, never before it: both
      // banners share one messenger, and a print failure that landed first
      // used to be wiped out by the callback's hideCurrentSnackBar above —
      // the operator saw "saved successfully", no paper, and no explanation.
      // The output choice is read from the sheet's live state: whatever the
      // operator last picked is what this sale follows. The sale is already
      // stored, so a failure here is only a snackbar — it never undoes it.
      _runOutput(saleArgs, _printSettings);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerLocationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 768;
            final body = _content(isWide);

            return Scaffold(backgroundColor: _p.scaffoldBg, body: body);
          },
        );
      },
    );
  }

  /// Replaces the back chevron in the top bar. Leaving a half-entered sale is
  /// a discard rather than plain navigation, so the control says so instead of
  /// hiding behind an arrow.
  Widget _cancelButton() {
    return TextButton(
      onPressed: _cancelSale,
      style: TextButton.styleFrom(
        foregroundColor: _mutedColor,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(48, 48),
        alignment: Alignment.centerLeft,
      ),
      child: Text(
        context.l10n.t('Cancel'),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _titleColor,
        ),
      ),
    );
  }

  void _cancelSale() {
    final navigator = Navigator.of(context);
    // Unsaved items mean the draft card in Add to Cart must survive this
    // exit, and the pop result tells the caller so: true = the sale was
    // saved and the draft can be consumed, false = keep it.
    final hasUnsavedItems = _viewModel.items.isNotEmpty;
    if (hasUnsavedItems) {
      // A simple in-app snackbar, not a push: the cashier is looking at
      // the screen and only needs to be told where the products went.
      showSuccessMessage(
        context,
        context.l10n.t(
          'Sale cancelled. Your products are saved in Add to Cart.',
        ),
      );
    }
    if (navigator.canPop()) {
      navigator.pop(!hasUnsavedItems);
    } else {
      navigateToDashboard(context);
    }
  }

  Widget _content(bool isWide) {
    return SafeArea(
      child: Column(
        children: [
          AppScreenTopBar(
            title: context.l10n.t('New Sale'),
            showMenuButton: false,
            leading: _cancelButton(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: isWide ? _wideBody() : _narrowBody(),
            ),
          ),
        ],
      ),
    );
  }

  /// Phone arrangement, byte-for-byte the stack the screen always had.
  Widget _narrowBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoCard(),
        const SizedBox(height: 24),
        _itemsSection(),
        const SizedBox(height: 24),
        _summaryCard(),
        const SizedBox(height: 24),
        _optionalFields(),
        const SizedBox(height: 24),
        _actionButtons(),
        const SizedBox(height: 16),
        _footerActions(),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Desktop/tablet arrangement: capped width, split into the working area
  /// (date, item list) on the left and the checkout column (totals, payment,
  /// notes, actions, print settings) on the right.
  Widget _wideBody() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoCard(),
                  const SizedBox(height: 24),
                  _itemsSection(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryCard(),
                  const SizedBox(height: 24),
                  _optionalFields(),
                  const SizedBox(height: 24),
                  _actionButtons(),
                  const SizedBox(height: 16),
                  _footerActions(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = _formatTime(now);
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: _mutedColor),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: _mutedColor),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _mutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final parts = dt.toFormattedDateTime().split(' ');
    return '${parts[parts.length - 2]} ${parts.last}';
  }

  Widget _itemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.t('Items'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _titleColor,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        if (_viewModel.items.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                context.l10n.t('No items added yet.'),
                style: TextStyle(color: _mutedColor, fontSize: 14),
              ),
            ),
          )
        else
          ...List.generate(
            _viewModel.items.length,
            (i) => KeyedSubtree(
              key: ValueKey(
                'sale_${i}_${_viewModel.items[i].productId}_${_viewModel.items[i].size}_${_viewModel.items[i].color}',
              ),
              child: _itemRow(i),
            ),
          ),
      ],
    );
  }

  Widget _itemRow(int index) {
    final item = _viewModel.items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _p.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _p.selectionTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.imageUrl != null
                      ? CachedProductImage(
                          url: item.imageUrl!,
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                          memCacheWidth: 160,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _titleColor,
                      ),
                    ),
                    if (item.category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: _mutedColor),
                      ),
                    ],
                    if (item.size != null ||
                        (item.color?.isNotEmpty == true)) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (item.size != null && item.size != 'Regular')
                            item.size,
                          if (item.color?.isNotEmpty == true) item.color,
                        ].where((e) => e != null && e.isNotEmpty).join(' | '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: _mutedColor),
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PriceText(
                      item.unitPrice,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _qtyLabel(index),
              const Spacer(),
              Text(
                context.l10n.t('Total:'),
                style: TextStyle(fontSize: 11, color: _mutedColor),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: PriceText(
                  item.subtotal,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyLabel(int index) {
    final qty = _viewModel.items[index].quantity;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.t('Qty: '),
            style: TextStyle(fontSize: 13, color: _mutedColor),
          ),
          Text(
            context.l10n.t('{v1}').replaceAll('{v1}', (qty).toString()),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return _card(
      child: TotalsPanel(
        padding: EdgeInsets.zero,
        itemCount: _viewModel.totalItems,
        subtotal: _viewModel.subtotal,
        discountPercent: _viewModel.discountPercent,
        discountAmount: _viewModel.discountAmount,
        totalPayable: _viewModel.totalPayable,
        discountEditor: TextField(
          controller: _discountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            const PercentInputFormatter(),
          ],
          onChanged: (v) =>
              _viewModel.setDiscountPercent(double.tryParse(v) ?? 0),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _titleColor,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _borderColor),
            ),
            suffixText: '%',
            suffixStyle: TextStyle(fontSize: 12, color: _mutedColor),
          ),
        ),
      ),
    );
  }

  Widget _optionalFields() {
    return Column(
      children: [
        _card(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.t('Payment Method'),
                  style: TextStyle(fontSize: 14, color: _mutedColor),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _viewModel.paymentMethod,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, size: 18),
                      items: [
                        DropdownMenuItem(
                          value: 'Cash',
                          child: Text(context.l10n.t('Cash')),
                        ),
                        DropdownMenuItem(
                          value: 'Card',
                          child: Text(context.l10n.t('Card')),
                        ),
                        DropdownMenuItem(
                          value: 'Mobile Pay',
                          child: Text(context.l10n.t('Mobile Pay')),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text(context.l10n.t('Other')),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) _viewModel.setPaymentMethod(v);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.t('Notes'),
                style: TextStyle(fontSize: 14, color: _mutedColor),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: TextStyle(fontSize: 14, color: _titleColor),
                onChanged: (v) => _viewModel.setNotes(v),
                decoration: InputDecoration(
                  hintText: context.l10n.t('Enter notes...'),
                  hintStyle: TextStyle(color: _p.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _borderColor),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: _outlineBtn(
            'Preview',
            Icons.visibility_outlined,
            false,
            () async {
              if (_viewModel.items.isEmpty) return;
              ShopScope.loadShop(
                context,
                shopId: AuthScope.userOf(context)?.shopId ?? '',
              );
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SalePreviewScreen(
                    customerName: _customerNameCtrl.text,
                    customerPhone: _customerPhoneCtrl.text.isNotEmpty
                        ? _customerPhoneCtrl.text
                        : null,
                    customerLocation: _customerLocationCtrl.text.isNotEmpty
                        ? _customerLocationCtrl.text
                        : null,
                    staffName: AuthScope.userOf(context)?.fullName ?? 'Staff',
                    voucherNo: 'INV-${_viewModel.voucherRandom}',
                    orderId: 'ORD-${_viewModel.orderRandom}',
                    dateTime: DateTime.now(),
                    items: List<SaleItemEntity>.from(_viewModel.items),
                    discountPct: _viewModel.discountPercent,
                    subtotal: _viewModel.subtotal,
                    discountAmt: _viewModel.discountAmount,
                    totalPayable: _viewModel.totalPayable,
                    paymentMethod: _viewModel.paymentMethod,
                    notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
                    shopName: ShopScope.shopOf(context)?.name,
                    shopAddress: ShopScope.shopOf(context)?.physicalAddress,
                    shopPhone: ShopScope.shopOf(
                      context,
                    )?.ownerInformation.phone,
                    shopEmail: ShopScope.shopOf(
                      context,
                    )?.ownerInformation.email,
                    shopImage:
                        ShopScope.shopOf(context)?.logoData ??
                        ShopScope.shopOf(context)?.logoUrl,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: (_viewModel.isSubmitting || _viewModel.items.isEmpty)
                ? null
                : _submitSale,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: (_viewModel.isSubmitting || _viewModel.items.isEmpty)
                    ? null
                    : const LinearGradient(
                        colors: [
                          AppColors.brandPurple,
                          AppColors.brandPurpleDark,
                        ],
                      ),
                color: (_viewModel.isSubmitting || _viewModel.items.isEmpty)
                    ? _mutedColor
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_viewModel.isSubmitting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    _viewModel.isSubmitting ? 'Saving...' : 'Sale',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _outlineBtn(
    String label,
    IconData icon,
    bool loading,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(
            color: loading ? _borderColor : AppColors.brandPurple,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brandPurple,
                ),
              )
            else
              Icon(icon, color: AppColors.brandPurple, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: loading ? _mutedColor : AppColors.brandPurple,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Runs the chosen post-sale output, best-effort: whatever the setting says
  /// (share a PDF, send to Bluetooth, send over Wi-Fi) happens here, and the
  /// only response to failure is a snackbar offering the OS print dialog as
  /// the manual way out — for the thermal outputs, where a bad connection
  /// should still end with paper.
  void _runOutput(Map<String, dynamic> args, SalePrintSettings settings) async {
    try {
      await SaleOutputService.printAfterSale(args, settings);
    } catch (e) {
      if (!mounted) return;
      final messageKey = settings.output == SalePrintSettings.outputPdf
          ? 'PDF export failed: {v1}'
          : 'Thermal printing failed: {v1}';
      showErrorDetail(
        context,
        context.l10n
            .t(messageKey)
            .replaceAll('{v1}', context.l10n.t(e.toString())),
        actionLabel: settings.isThermal
            ? context.l10n.t('Open print dialog')
            : null,
        onAction: settings.isThermal
            ? () async {
                try {
                  await ReceiptPrintService.printReceipt(args, settings);
                } catch (fallbackError) {
                  if (!mounted) return;
                  showErrorDetail(
                    context,
                    context.l10n
                        .t('Thermal printing failed: {v1}')
                        .replaceAll(
                          '{v1}',
                          context.l10n.t(fallbackError.toString()),
                        ),
                  );
                }
              }
            : null,
      );
    }
  }

  /// The settings sheet's live values, packaged the way the service reads
  /// them — one implementation behind both sale surfaces.
  SalePrintSettings get _printSettings => SalePrintSettings(
    output: _output,
    paperSize: _paperSize,
    btPrinterAddress: _btPrinterAddress,
    btPrinterName: _btPrinterName,
  );

  void _showPrintSettings() {
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
                            color: _borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.t('Print Settings'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _titleColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Icon(Icons.close, color: _mutedColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Output'),
                      const SizedBox(height: 10),
                      _outputOption(
                        setSheetState,
                        title: context.l10n.t('PDF'),
                        subtitle: context.l10n.t('Save PDF file after sale'),
                        value: SalePrintSettings.outputPdf,
                        icon: Icons.picture_as_pdf,
                      ),
                      const SizedBox(height: 8),
                      // WebUSB is the browser's only direct thermal path, so
                      // on the web build it sits above the pair the browser
                      // cannot reach (Bluetooth SPP / raw TCP).
                      if (UsbPrinterTransport.isSupported) ...[
                        _outputOption(
                          setSheetState,
                          title: context.l10n.t('USB'),
                          subtitle: context.l10n.t(
                            'Print directly to a USB thermal printer',
                          ),
                          value: SalePrintSettings.outputUsb,
                          icon: Icons.usb,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _outputOption(
                        setSheetState,
                        title: context.l10n.t('Bluetooth'),
                        subtitle: context.l10n.t(
                          'Print directly to a Bluetooth thermal printer',
                        ),
                        value: SalePrintSettings.outputBluetooth,
                        icon: Icons.bluetooth,
                        enabled: ThermalPrinterTransport.isSupported,
                      ),
                      const SizedBox(height: 8),
                      _outputOption(
                        setSheetState,
                        title: context.l10n.t('Wi-Fi'),
                        subtitle: context.l10n.t(
                          'Print directly to a network thermal printer',
                        ),
                        value: SalePrintSettings.outputWifi,
                        icon: Icons.wifi,
                        enabled: ThermalPrinterTransport.isSupported,
                      ),
                      if (!ThermalPrinterTransport.isSupported &&
                          !UsbPrinterTransport.isSupported) ...[
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.t(
                            'Thermal printing is not available here',
                          ),
                          style: TextStyle(fontSize: 12, color: _mutedColor),
                        ),
                      ],
                      if (_output == SalePrintSettings.outputUsb)
                        _usbSection(ctx, setSheetState),
                      if (_output == SalePrintSettings.outputBluetooth)
                        _bluetoothSection(ctx, setSheetState),
                      if (_output == SalePrintSettings.outputWifi)
                        _wifiSection(),
                      if (_output != SalePrintSettings.outputPdf)
                        _paperSizeSection(ctx, setSheetState),
                      const SizedBox(height: 24),
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

  Widget _sectionTitle(String key) => Text(
    context.l10n.t(key),
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: _titleColor,
    ),
  );

  /// One of the three outputs. Disabled options (the thermal pair in a
  /// browser) stay visible so the choice reads as deliberate rather than
  /// mysteriously missing, but they cannot be tapped.
  Widget _outputOption(
    StateSetter setSheetState, {
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    bool enabled = true,
  }) {
    final isSelected = _output == value;
    return GestureDetector(
      onTap: enabled
          ? () {
              setSheetState(() => _output = value);
              setState(() => _output = value);
              _savePrintSettings();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? _p.selectionTint : _p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? _accentColor : _borderColor),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? _accentColor : _mutedColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? _accentColor : _titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: _mutedColor),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: _accentColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Which USB printer [SalePrintSettings.outputUsb] prints to — the device
  /// the browser's WebUSB chooser granted, remembered so the sheet can say
  /// what is selected without re-opening the chooser.
  Widget _usbSection(BuildContext ctx, StateSetter setSheetState) {
    final chosen = _usbPrinter != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _sectionTitle('USB Printer'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _p.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.usb,
                  color: chosen ? _accentColor : _mutedColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chosen
                          ? _usbPrinter!.name
                          : context.l10n.t('No printer selected'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chosen
                          ? 'id:${_usbPrinter!.vendorId.toRadixString(16).padLeft(4, '0')}:${_usbPrinter!.productId.toRadixString(16).padLeft(4, '0')}'
                          : context.l10n.t('Plug in the printer, then choose'),
                      style: TextStyle(fontSize: 12, color: _mutedColor),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _pickUsbPrinter(ctx, setSheetState),
                child: Text(
                  context.l10n.t(chosen ? 'Change' : 'Choose'),
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        // The one-time driver swap lives outside the browser, so the link to
        // it sits with the USB card it applies to — where a till would hit
        // the error it prevents.
        if (UsbPrinterTransport.isSupported)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _openUsbSetupDownload,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(
                context.l10n.t('Download USB setup for this computer'),
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Fetches the one-time Windows driver package. A refused launch (popup
  /// blocker) says so rather than leaving the operator with nothing.
  Future<void> _openUsbSetupDownload() async {
    final ok = await UsbSetupDownload.open();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.t('The download could not be started. Try again.'),
          ),
        ),
      );
    }
  }

  /// Opens the browser's WebUSB chooser. Must stay on the tap's user
  /// gesture — Chrome rejects [requestDevice] after an await.
  Future<void> _pickUsbPrinter(
    BuildContext sheetCtx,
    StateSetter setSheetState,
  ) async {
    try {
      final picked = await UsbPrinterTransport.requestDevice();
      if (!sheetCtx.mounted) return;
      setSheetState(() => _usbPrinter = picked);
      setState(() => _usbPrinter = picked);
      // Choosing a USB printer is an explicit intent to print to it.
      setState(() => _output = SalePrintSettings.outputUsb);
      setSheetState(() => _output = SalePrintSettings.outputUsb);
      await _savePrintSettings();
    } catch (e) {
      if (!sheetCtx.mounted) return;
      showErrorDetail(sheetCtx, e.toString());
    }
  }

  /// Which Bluetooth printer the [SalePrintSettings.outputBluetooth] output
  /// prints to — remembered, not re-discovered, so the sheet can say what is
  /// selected even with the adapter off.
  Widget _bluetoothSection(BuildContext ctx, StateSetter setSheetState) {
    final chosen = _btPrinterAddress.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _sectionTitle('Bluetooth Printer'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _p.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bluetooth,
                  color: chosen ? _accentColor : _mutedColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chosen && _btPrinterName.isNotEmpty
                          ? _btPrinterName
                          : context.l10n.t('No printer selected'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chosen ? _btPrinterAddress : '',
                      style: TextStyle(fontSize: 12, color: _mutedColor),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _pickBluetoothPrinter(ctx, setSheetState),
                child: Text(
                  context.l10n.t(chosen ? 'Change' : 'Choose'),
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Where [SalePrintSettings.outputWifi] prints: the default network printer
  /// from Printer settings, shown so the operator can confirm the till is
  /// pointed at the right machine without leaving the sale.
  Widget _wifiSection() {
    final printer = _wifiPrinter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _sectionTitle('Network Printer'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _p.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.wifi,
                  color: printer != null ? _accentColor : _mutedColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      printer != null
                          ? printer.name
                          : context.l10n.t('No printer configured'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      printer != null
                          ? '${printer.host}:${printer.port}'
                          : context.l10n.t(
                              'Add a printer in Settings > Printers',
                            ),
                      style: TextStyle(fontSize: 12, color: _mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paperSizeSection(BuildContext ctx, StateSetter setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _sectionTitle('Paper Size'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _paperSizeOption(
                ctx,
                setSheetState,
                '58mm',
                Icons.crop_free,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _paperSizeOption(
                ctx,
                setSheetState,
                '80mm',
                Icons.aspect_ratio,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Opens the picker above the settings sheet, then stores the choice.
  Future<void> _pickBluetoothPrinter(
    BuildContext sheetCtx,
    StateSetter setSheetState,
  ) async {
    final picked = await showModalBottomSheet<BluetoothPrinterCandidate>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          BluetoothPrinterPicker(selectedAddress: _btPrinterAddress),
    );
    if (picked == null || !mounted) return;
    await SalePrintSettings.setBluetoothPrinter(
      address: picked.address,
      name: picked.name,
    );
    if (!mounted) return;
    setState(() {
      _btPrinterAddress = picked.address;
      _btPrinterName = picked.name;
    });
    // The settings sheet is its own route above this screen: the screen's
    // setState does not repaint it, so nudge it too.
    setSheetState(() {});
  }

  Widget _paperSizeOption(
    BuildContext ctx,
    StateSetter setSheetState,
    String label,
    IconData icon,
  ) {
    final isSelected = _paperSize == label;
    return GestureDetector(
      onTap: () {
        setSheetState(() => _paperSize = label);
        setState(() => _paperSize = label);
        _savePrintSettings();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _p.selectionTint : _p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? _accentColor : _borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? _accentColor : _mutedColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? _accentColor : _titleColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, color: _accentColor, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _footerActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _showPrintSettings,
          child: _footerBtn(Icons.settings_outlined, 'Print Settings'),
        ),
        Container(
          width: 1,
          height: 20,
          color: _borderColor,
          margin: const EdgeInsets.symmetric(horizontal: 20),
        ),
        GestureDetector(
          onTap: () {
            // Deliberately *not* navigateToDestination: that pops back to a
            // Sale Item screen below this one, which would throw away the
            // sale being written here. A drill-down gets its own route.
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => SaleItemScreen()));
          },
          child: _footerBtn(Icons.history, 'Recent Sales'),
        ),
      ],
    );
  }

  Widget _footerBtn(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: _mutedColor, size: 18),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: _mutedColor)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _p.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
