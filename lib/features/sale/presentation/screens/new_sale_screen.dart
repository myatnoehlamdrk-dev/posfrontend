import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_repository_impl.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_product_repository_impl.dart';
import 'package:posfrontend/features/sale/presentation/screens/add_products_screen.dart';
import 'package:posfrontend/features/sale/presentation/screens/sale_preview_screen.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/sale_view_model.dart';
import 'package:posfrontend/shared/services/voucher_pdf_service.dart';
import 'package:posfrontend/features/sale/presentation/screens/sale_items_screen.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/error_snackbar.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _customerNameCtrl = TextEditingController(text: 'Customer');
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
      showErrorSnackBar(context, Exception(_viewModel.errorMessage ?? 'Failed to save sale'));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sale saved successfully!'), backgroundColor: Color(0xFF16A34A)),
    );

    final itemsSnapshot = List<SaleItemEntity>.from(_viewModel.items);
    final customerName = _customerNameCtrl.text;
    final customerPhone = _customerPhoneCtrl.text.isNotEmpty ? _customerPhoneCtrl.text : null;
    final customerLocation = _customerLocationCtrl.text.isNotEmpty ? _customerLocationCtrl.text : null;
    final paymentMethod = _viewModel.paymentMethod;
    final notes = _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null;
    final voucherNo = 'INV-${_viewModel.voucherRandom}';
    final orderId = widget.existingOrderId ?? 'ORD-${_viewModel.orderRandom}';

    setState(() {
      _customerNameCtrl.text = 'Customer';
      _customerPhoneCtrl.clear();
      _customerLocationCtrl.clear();
      _discountCtrl.text = '0';
      _notesCtrl.clear();
    });
    _viewModel.clearCart();

    if (_pdfExportEnabled || _printVoucherEnabled) {
      final saleArgs = _buildSaleArgs(customerName, customerPhone, customerLocation, staffName, voucherNo, orderId, itemsSnapshot, _viewModel.discountPercent, _viewModel.totalPayable, paymentMethod, notes);
      if (_pdfExportEnabled) _autoExportPdf(saleArgs);
      if (_printVoucherEnabled) _autoPrintVoucher(saleArgs);
    }
  }

  Future<void> _submitDraft() async {
    final staffName = AuthScope.userOf(context)?.fullName ?? 'Staff';
    _viewModel.setCustomerName(_customerNameCtrl.text);
    _viewModel.setCustomerPhone(_customerPhoneCtrl.text);
    _viewModel.setCustomerLocation(_customerLocationCtrl.text);
    final success = await _viewModel.submitDraft(staffName: staffName);
    if (!success) {
      if (!mounted) return;
      showErrorSnackBar(context, Exception(_viewModel.errorMessage ?? 'Failed to save draft'));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved successfully!'), backgroundColor: Color(0xFF2563EB)),
    );
    setState(() {
      _customerNameCtrl.text = 'Customer';
      _customerPhoneCtrl.clear();
      _customerLocationCtrl.clear();
      _discountCtrl.text = '0';
      _notesCtrl.clear();
    });
    _viewModel.clearCart();
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

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: kBg,
              drawer: isWide ? null : const AppDrawer(activeItem: 'Sale'),
              body: isWide
                  ? Row(
                      children: [
                        const SizedBox(
                            width: 240,
                            child: AppDrawer(activeItem: 'Sale')),
                        Expanded(child: body),
                      ],
                    )
                  : body,
            );
          },
        );
      },
    );
  }

  Widget _content(bool isWide) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTopBar(
              title: 'New Sale',
              showMenuButton: !isWide,
              showBackButton: isWide,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(height: 20),
            Breadcrumb([
              const BreadcrumbItem('Dashboard', false),
              const BreadcrumbItem('Sale', false),
              const BreadcrumbItem('New Sale', true),
            ]),
            const SizedBox(height: 24),
            _customerCard(),
            const SizedBox(height: 16),
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
    );
  }

  Widget _customerCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: kPurple, size: 22),
              ),
              const SizedBox(width: 14),
              const Text('Customer',
                  style: TextStyle(fontSize: 12, color: kGray)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _customerNameCtrl,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kTitle),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (q) => _viewModel.searchCustomers(q),
                      onTap: () => _viewModel.showCustomerSuggestions(),
                    ),
                    if (_viewModel.showSuggestions && _viewModel.customerSuggestions.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 160),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _viewModel.customerSuggestions.length,
                          itemBuilder: (context, index) {
                            final c = _viewModel.customerSuggestions[index];
                            return InkWell(
                              onTap: () {
                                _viewModel.selectCustomer(c);
                                _customerNameCtrl.text = _viewModel.customerName;
                                if (_viewModel.customerPhone.isNotEmpty) {
                                  _customerPhoneCtrl.text = _viewModel.customerPhone;
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 16, color: kGray),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c['name'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: kTitle),
                                          ),
                                          if (c['phone'] != null &&
                                              (c['phone'] as String)
                                                  .isNotEmpty)
                                            Text(
                                              c['phone'],
                                              style: const TextStyle(
                                                  fontSize: 12, color: kGray),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: kPurple, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone, color: kPurple, size: 22),
              ),
              const SizedBox(width: 14),
              const Text('Phone',
                  style: TextStyle(fontSize: 12, color: kGray)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _customerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kTitle),
                  decoration: InputDecoration(
                    hintText: 'Optional',
                    hintStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFD1D5DB)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on, color: kPurple, size: 22),
              ),
              const SizedBox(width: 14),
              const Text('Location',
                  style: TextStyle(fontSize: 12, color: kGray)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _customerLocationCtrl,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kTitle),
                  decoration: InputDecoration(
                    hintText: 'Optional',
                    hintStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFD1D5DB)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = _formatTime(now);
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Voucher No.',
                    style: TextStyle(fontSize: 12, color: kGray)),
                const SizedBox(height: 4),
                Text('INV-${_viewModel.voucherRandom}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB))),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: kBorder),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: kGray),
                    const SizedBox(width: 6),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kTitle)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: kGray),
                    const SizedBox(width: 6),
                    Text(timeStr,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: kGray)),
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
            const Text('Items',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTitle)),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.of(context).push<List<SaleItemEntity>>(
                  MaterialPageRoute(builder: (_) => const AddProductsScreen()),
                );
                if (result != null && result.isNotEmpty) {
                  _viewModel.addItems(result);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_viewModel.items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No items added yet.',
                  style: TextStyle(color: kGray, fontSize: 14)),
            ),
          )
        else
          ...List.generate(_viewModel.items.length, (i) => KeyedSubtree(
            key: ValueKey('sale_${_viewModel.items[i].productId}_${_viewModel.items[i].size}_${_viewModel.items[i].color}'),
            child: _itemRow(i),
          )),
      ],
    );
  }

  Widget _itemRow(int index) {
    final item = _viewModel.items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
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
                    color: const Color(0xFFF5F0FF),
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: kTitle),
                    ),
                    if (item.category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: kGray),
                      ),
                    ],
                    if (item.size != null || (item.color?.isNotEmpty == true)) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (item.size != null && item.size != 'Regular') item.size,
                          if (item.color?.isNotEmpty == true) item.color,
                        ].where((e) => e != null && e.isNotEmpty).join(' | '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: kGray),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PriceText(item.unitPrice,
                      maxLength: 10,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kTitle)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _viewModel.removeItem(index),
                    child: const Icon(Icons.delete_outline,
                        color: kRed, size: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _qtyControl(index),
              const Spacer(),
              const Text('Total:',
                  style: TextStyle(fontSize: 11, color: kGray)),
              const SizedBox(width: 4),
              PriceText(item.subtotal,
                  maxLength: 12,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTitle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyControl(int index) {
    final qty = _viewModel.items[index].quantity;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _qtyBtn(Icons.remove, () => _viewModel.updateItemQuantity(index, -1)),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text('$qty',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTitle)),
          ),
          _qtyBtn(Icons.add, () => _viewModel.updateItemQuantity(index, 1)),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: kGray),
      ),
    );
  }

  Widget _summaryCard() {
    return _card(
      child: Column(
        children: [
          _summaryRow('Total Items', '${_viewModel.totalItems}'),
          const SizedBox(height: 12),
          _summaryPriceRow('Subtotal', _viewModel.subtotal),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Discount',
                  style: TextStyle(fontSize: 14, color: kGray)),
              const Spacer(),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _discountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => _viewModel.setDiscountPercent(double.tryParse(v) ?? 0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: kTitle),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kBorder)),
                    suffixText: '%',
                    suffixStyle:
                        const TextStyle(fontSize: 12, color: kGray),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryPriceRow('Discount Amount', _viewModel.discountAmount),
          const Divider(height: 24, color: kBorder),
          Row(
            children: [
              const Text('Total Payable',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTitle)),
              const Spacer(),
              PriceText(_viewModel.totalPayable,
                  maxLength: 12,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: kGray)),
        const Spacer(),
        Flexible(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kTitle)),
        ),
      ],
    );
  }

  Widget _summaryPriceRow(String label, double amount) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: kGray)),
        const Spacer(),
        PriceText(amount,
            maxLength: 12,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: kTitle)),
      ],
    );
  }

  Widget _optionalFields() {
    return Column(
      children: [
        _card(
          child: Row(
            children: [
              const Expanded(
                child: Text('Order ID',
                    style: TextStyle(fontSize: 14, color: kGray)),
              ),
              Expanded(
                flex: 2,
                child: Text('ORD-${_viewModel.orderRandom}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2563EB))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Row(
            children: [
              const Expanded(
                child: Text('Payment Method',
                    style: TextStyle(fontSize: 14, color: kGray)),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _viewModel.paymentMethod,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'Card', child: Text('Card')),
                        DropdownMenuItem(value: 'Mobile Pay', child: Text('Mobile Pay')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
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
              const Text('Notes',
                  style: TextStyle(fontSize: 14, color: kGray)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, color: kTitle),
                onChanged: (v) => _viewModel.setNotes(v),
                decoration: InputDecoration(
                  hintText: 'Enter notes...',
                  hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kBorder)),
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
          child: _outlineBtn('Draft', Icons.save_outlined, () {
            if (_viewModel.items.isEmpty) return;
            _submitDraft();
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _outlineBtn('Preview', Icons.visibility_outlined, () async {
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
                  customerPhone: _customerPhoneCtrl.text.isNotEmpty ? _customerPhoneCtrl.text : null,
                  customerLocation: _customerLocationCtrl.text.isNotEmpty ? _customerLocationCtrl.text : null,
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
                  shopPhone: ShopScope.shopOf(context)?.ownerInformation.phone,
                  shopEmail: ShopScope.shopOf(context)?.ownerInformation.email,
                  shopImage: ShopScope.shopOf(context)?.logoData ?? ShopScope.shopOf(context)?.logoUrl,
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: (_viewModel.isSubmitting || _viewModel.items.isEmpty) ? null : _submitSale,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: (_viewModel.isSubmitting || _viewModel.items.isEmpty)
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                color: (_viewModel.isSubmitting || _viewModel.items.isEmpty) ? kGray : null,
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
                          strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(_viewModel.isSubmitting ? 'Saving...' : 'Sale',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _outlineBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2563EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _buildSaleArgs(String customerName, String? customerPhone, String? customerLocation, String staffName, String voucherNo, String orderId, List<SaleItemEntity> items, double discountPct, double totalPayable, String paymentMethod, String? notes) {
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
      'subtotal': _viewModel.subtotal,
      'discountAmt': _viewModel.discountAmount,
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
        await Printing.sharePdf(bytes: pdfBytes, filename: 'Voucher_${args['voucherNo']}.pdf');
      }
    } catch (_) {
      // PDF export failure is non-critical
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
    } catch (_) {
      // Print voucher failure is non-critical
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                          decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Print Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kTitle)),
                          GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, color: kGray)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _toggleRow(
                        icon: Icons.picture_as_pdf,
                        title: 'Export PDF',
                        subtitle: 'Save PDF file after sale',
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
                        title: 'Print Voucher',
                        subtitle: 'Auto-print after sale',
                        value: _printVoucherEnabled,
                        onChanged: (v) {
                          setSheetState(() => _printVoucherEnabled = v);
                          setState(() => _printVoucherEnabled = v);
                          _savePrintSettings();
                        },
                      ),
                      if (_printVoucherEnabled) ...[
                        const SizedBox(height: 20),
                        const Text('Print Format', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTitle)),
                        const SizedBox(height: 10),
                        _formatOption(ctx, setSheetState, 'Thermal Paper', 'thermal', Icons.receipt_long),
                        const SizedBox(height: 8),
                        _formatOption(ctx, setSheetState, 'A4 Paper', 'a4', Icons.description_outlined),
                      ],
                      if (_printVoucherEnabled && _printFormat == 'thermal') ...[
                        const SizedBox(height: 20),
                        const Text('Paper Size', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTitle)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _paperSizeOption(ctx, setSheetState, '58mm', Icons.crop_free),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _paperSizeOption(ctx, setSheetState, '80mm', Icons.aspect_ratio),
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

  Widget _formatOption(BuildContext ctx, StateSetter setSheetState, String label, String value, IconData icon) {
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
          color: isSelected ? const Color(0xFFF5F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? kPurple : kBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kPurple : kGray, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? kPurple : kTitle))),
            if (isSelected) const Icon(Icons.check_circle, color: kPurple, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _paperSizeOption(BuildContext ctx, StateSetter setSheetState, String label, IconData icon) {
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
          color: isSelected ? const Color(0xFFF5F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? kPurple : kBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? kPurple : kGray, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? kPurple : kTitle)),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, color: kPurple, size: 18),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kGray, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTitle)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: kGray)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: kPurple,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: kBorder,
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
          color: kBorder,
          margin: const EdgeInsets.symmetric(horizontal: 20),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SaleItemScreen(),
              ),
            );
          },
          child: _footerBtn(Icons.history, 'Recent Sales'),
        ),
      ],
    );
  }

  Widget _footerBtn(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: kGray, size: 18),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 13, color: kGray)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
