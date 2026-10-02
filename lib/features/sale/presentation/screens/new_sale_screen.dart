import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:posfrontend/features/sale/presentation/widgets/percent_input_formatter.dart';
import 'package:posfrontend/shared/services/voucher_pdf_service.dart';
import 'package:posfrontend/features/sale/presentation/screens/sale_items_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/totals_panel.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';
import 'package:printing/printing.dart';

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

  bool _pdfExportEnabled = true;
  bool _printVoucherEnabled = false;
  String _printFormat = 'thermal';
  String _paperSize = '58mm';
  static const _keyPdfExport = 'print_pdf_export';
  static const _keyPrintVoucher = 'print_voucher_enabled';
  static const _keyPrintFormat = 'print_format';
  static const _keyPaperSize = 'print_paper_size';

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
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pdfExportEnabled = prefs.getBool(_keyPdfExport) ?? true;
      _printVoucherEnabled = prefs.getBool(_keyPrintVoucher) ?? false;
      _printFormat = prefs.getString(_keyPrintFormat) ?? 'thermal';
      _paperSize = prefs.getString(_keyPaperSize) ?? '58mm';
    });
  }

  Future<void> _savePrintSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPdfExport, _pdfExportEnabled);
    await prefs.setBool(_keyPrintVoucher, _printVoucherEnabled);
    await prefs.setString(_keyPrintFormat, _printFormat);
    await prefs.setString(_keyPaperSize, _paperSize);
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
    final saleArgs = _buildSaleArgs(
      customerName,
      customerPhone,
      customerLocation,
      staffName,
      voucherNo,
      orderId,
      itemsSnapshot,
      _viewModel.discountPercent,
      _viewModel.subtotal,
      _viewModel.discountAmount,
      _viewModel.totalPayable,
      paymentMethod,
      notes,
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

    if (_pdfExportEnabled || _printVoucherEnabled) {
      if (_pdfExportEnabled) _autoExportPdf(saleArgs);
      if (_printVoucherEnabled) _autoPrintVoucher(saleArgs);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !messenger.mounted) return;
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

  Widget _content(bool isWide) {
    return SafeArea(
      child: Column(
        children: [
          AppScreenTopBar(
            title: context.l10n.t('New Sale'),
            showMenuButton: false,
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
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
              ),
            ),
          ),
        ],
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
                      ? Image.network(item.imageUrl!, fit: BoxFit.cover)
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

  Map<String, dynamic> _buildSaleArgs(
    String customerName,
    String? customerPhone,
    String? customerLocation,
    String staffName,
    String voucherNo,
    String orderId,
    List<SaleItemEntity> items,
    double discountPct,
    double subtotal,
    double discountAmt,
    double totalPayable,
    String paymentMethod,
    String? notes,
  ) {
    final shop = ShopScope.shopOf(context);
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerLocation': customerLocation,
      'staffName': staffName,
      'voucherNo': voucherNo,
      'orderId': orderId,
      'dateTime': DateTime.now(),
      'items': items,
      'discountPct': discountPct,
      'subtotal': subtotal,
      'discountAmt': discountAmt,
      'totalPayable': totalPayable,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'shopName': shop?.name,
      'shopAddress': shop?.physicalAddress,
      'shopPhone': shop?.ownerInformation.phone,
      'shopImage': shop?.logoUrl ?? shop?.logoData,
    };
  }

  void _autoExportPdf(Map<String, dynamic> args) async {
    try {
      final pdfBytes = await VoucherPdfService.exportA4Pdf(
        customerName: args['customerName'],
        customerPhone: args['customerPhone'],
        staffName: args['staffName'],
        voucherNo: args['voucherNo'],
        orderId: args['orderId'],
        dateTime: args['dateTime'],
        items: args['items'],
        discountPct: args['discountPct'],
        subtotal: args['subtotal'],
        discountAmt: args['discountAmt'],
        totalPayable: args['totalPayable'],
        paymentMethod: args['paymentMethod'],
        notes: args['notes'],
        shopName: args['shopName'],
        shopAddress: args['shopAddress'],
        shopPhone: args['shopPhone'],
        shopImage: args['shopImage'],
      );
      if (mounted) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Voucher_${args['voucherNo']}.pdf',
        );
      }
    } catch (e) {
      if (mounted)
        showErrorMessage(
          context,
          context.l10n
              .t('PDF export failed: {v1}')
              .replaceAll('{v1}', (e).toString()),
        );
    }
  }

  void _autoPrintVoucher(Map<String, dynamic> args) async {
    try {
      if (_printFormat == 'thermal') {
        final paperWidthMm = _paperSize == '80mm' ? 78.0 : 56.7;
        await VoucherPdfService.generateAndPrintReceipt(
          customerName: args['customerName'],
          customerPhone: args['customerPhone'],
          staffName: args['staffName'],
          voucherNo: args['voucherNo'],
          orderId: args['orderId'],
          dateTime: args['dateTime'],
          items: args['items'],
          discountPct: args['discountPct'],
          subtotal: args['subtotal'],
          discountAmt: args['discountAmt'],
          totalPayable: args['totalPayable'],
          paymentMethod: args['paymentMethod'],
          notes: args['notes'],
          shopName: args['shopName'],
          shopAddress: args['shopAddress'],
          shopPhone: args['shopPhone'],
          shopImage: args['shopImage'],
          paperWidthMm: paperWidthMm,
          customerLocation: args['customerLocation'],
        );
      } else {
        await VoucherPdfService.generateAndPrint(
          customerName: args['customerName'],
          customerPhone: args['customerPhone'],
          staffName: args['staffName'],
          voucherNo: args['voucherNo'],
          orderId: args['orderId'],
          dateTime: args['dateTime'],
          items: args['items'],
          discountPct: args['discountPct'],
          subtotal: args['subtotal'],
          discountAmt: args['discountAmt'],
          totalPayable: args['totalPayable'],
          paymentMethod: args['paymentMethod'],
          notes: args['notes'],
          shopName: args['shopName'],
          shopAddress: args['shopAddress'],
          shopPhone: args['shopPhone'],
          shopImage: args['shopImage'],
        );
      }
    } catch (e) {
      if (mounted)
        showErrorMessage(
          context,
          context.l10n
              .t('Thermal printing failed: {v1}')
              .replaceAll('{v1}', (e).toString()),
        );
    }
  }

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
                      _toggleRow(
                        icon: Icons.picture_as_pdf,
                        title: context.l10n.t('Export PDF'),
                        subtitle: context.l10n.t('Save PDF file after sale'),
                        value: _pdfExportEnabled,
                        onChanged: (v) {
                          setSheetState(() => _pdfExportEnabled = v);
                          setState(() => _pdfExportEnabled = v);
                          _savePrintSettings();
                        },
                      ),
                      const SizedBox(height: 16),
                      _toggleRow(
                        icon: Icons.print_outlined,
                        title: context.l10n.t('Print Voucher'),
                        subtitle: context.l10n.t('Auto-print after sale'),
                        value: _printVoucherEnabled,
                        onChanged: (v) {
                          setSheetState(() => _printVoucherEnabled = v);
                          setState(() => _printVoucherEnabled = v);
                          _savePrintSettings();
                        },
                      ),
                      if (_printVoucherEnabled) ...[
                        const SizedBox(height: 20),
                        Text(
                          context.l10n.t('Print Format'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _titleColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _formatOption(
                          ctx,
                          setSheetState,
                          'Thermal Paper',
                          'thermal',
                          Icons.receipt_long,
                        ),
                        const SizedBox(height: 8),
                        _formatOption(
                          ctx,
                          setSheetState,
                          'A4 Paper',
                          'a4',
                          Icons.description_outlined,
                        ),
                      ],
                      if (_printVoucherEnabled &&
                          _printFormat == 'thermal') ...[
                        const SizedBox(height: 20),
                        Text(
                          context.l10n.t('Paper Size'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _titleColor,
                          ),
                        ),
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

  Widget _formatOption(
    BuildContext ctx,
    StateSetter setSheetState,
    String label,
    String value,
    IconData icon,
  ) {
    final isSelected = _printFormat == value;
    return GestureDetector(
      onTap: () {
        setSheetState(() => _printFormat = value);
        setState(() => _printFormat = value);
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
          children: [
            Icon(
              icon,
              color: isSelected ? _accentColor : _mutedColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? _accentColor : _titleColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: _accentColor, size: 20),
          ],
        ),
      ),
    );
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

  Widget _toggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
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
            child: Icon(icon, color: _mutedColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _accentColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _borderColor,
          ),
        ],
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
