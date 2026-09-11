import 'dart:math';
import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/sale/model/sale_models.dart';
import 'package:posfrontend/modules/sale/repository/order_repository_impl.dart';
import 'package:posfrontend/modules/sale/repository/sale_product_repository_impl.dart';
import 'package:posfrontend/modules/sale/repository/sale_repository_impl.dart';
import 'package:posfrontend/modules/sale/view/add_products_screen.dart';
import 'package:posfrontend/modules/sale/view/sale_preview_screen.dart';
import 'package:posfrontend/modules/sale/viewmodel/sale_view_model.dart';
import 'package:posfrontend/modules/sale/service/voucher_pdf_service.dart';
import 'package:posfrontend/modules/sale_items/view/sale_items_screen.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/modules/shared/widgets/price_text.dart';
import 'package:posfrontend/modules/shop/model/shop.dart';
import 'package:posfrontend/modules/shop/repository/shop_api_repository_impl.dart';
import 'package:posfrontend/modules/shop/repository/shop_local_repository_impl.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';

class NewSaleScreen extends StatefulWidget {
  final LoginResponse? user;
  final List<SaleItem>? initialItems;
  final String? initialCustomerName;
  final String? initialCustomerPhone;
  final String? initialPaymentMethod;
  final String? existingOrderId;
  const NewSaleScreen({
    super.key,
    this.user,
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
  final SaleViewModel _viewModel = SaleViewModel(
    productRepository: SaleProductRepositoryImpl(),
    saleRepository: SaleRepositoryImpl(),
  );

  String _paymentMethod = 'Cash';
  late String _voucherRandom;
  late String _orderRandom;
  bool _isSubmitting = false;
  bool _pdfExportEnabled = true;
  bool _voucherPaperEnabled = true;
  Shop? _shop;

  final List<SaleItem> _items = [];

  String _generateRandom5() {
    final rand = Random();
    return (10000 + rand.nextInt(90000)).toString();
  }

  @override
  void initState() {
    super.initState();
    _voucherRandom = _generateRandom5();
    _orderRandom = _generateRandom5();
    if (widget.initialItems != null) {
      _items.addAll(widget.initialItems!);
    }
    if (widget.initialCustomerName?.isNotEmpty == true) {
      _customerNameCtrl.text = widget.initialCustomerName!;
    }
    if (widget.initialCustomerPhone != null) {
      _customerPhoneCtrl.text = widget.initialCustomerPhone!;
    }
    if (widget.initialPaymentMethod != null) {
      _paymentMethod = widget.initialPaymentMethod!;
    }
    _loadShop();
  }

  Future<void> _loadShop() async {
    try {
      final shopId = widget.user?.shopId ?? '';
      if (shopId.isNotEmpty) {
        final shop = await ShopApiRepositoryImpl().getShopById(shopId);
        if (mounted) setState(() => _shop = shop);
        return;
      }
    } catch (_) {}
    final shop = await ShopLocalRepositoryImpl().getShop();
    if (mounted && shop != null) setState(() => _shop = shop);
  }

  void _refreshRandoms() {
    setState(() {
      _voucherRandom = _generateRandom5();
      _orderRandom = _generateRandom5();
    });
  }

  Future<void> _submitSale() async {
    if (_items.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final discountPct = _discountPct;
      final subtotal = _subtotal;
      final discountAmt = _discountAmt;
      final totalPayable = _totalPayable;
      final items = List<SaleItem>.from(_items);
      final customerName = _customerNameCtrl.text;
      final customerPhone = _customerPhoneCtrl.text.isNotEmpty ? _customerPhoneCtrl.text : null;
      final paymentMethod = _paymentMethod;
      final notes = _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null;
      final staffName = widget.user?.fullName ?? 'Staff';
      final voucherNo = 'INV-$_voucherRandom';
      final orderId = widget.existingOrderId ?? 'ORD-$_orderRandom';

      await _viewModel.submitSale(
        userName: staffName,
        customerName: customerName,
        customerPhone: customerPhone,
        payMethod: paymentMethod,
        voucherNo: voucherNo,
        orderId: orderId,
        items: items,
        grandTotal: totalPayable,
        discount: discountPct.toInt(),
        notes: notes,
      );

      if (widget.existingOrderId != null) {
        try {
          await OrderRepositoryImpl().deleteOrder(widget.existingOrderId!);
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale saved successfully!'), backgroundColor: Color(0xFF16A34A)),
      );

      if (_pdfExportEnabled) {
        await VoucherPdfService.generateAndPrint(
          customerName: customerName,
          customerPhone: customerPhone,
          staffName: staffName,
          voucherNo: voucherNo,
          orderId: orderId,
          dateTime: DateTime.now(),
          items: items,
          discountPct: discountPct,
          subtotal: subtotal,
          discountAmt: discountAmt,
          totalPayable: totalPayable,
          paymentMethod: paymentMethod,
          notes: notes,
          shopName: _shop?.name,
          shopAddress: _shop?.physicalAddress,
          shopPhone: _shop?.ownerInformation.phone,
          shopImage: _shop?.logoUrl ?? _shop?.logoData,
        );
      }

      setState(() {
        _items.clear();
        _customerNameCtrl.text = 'Customer';
        _customerPhoneCtrl.clear();
        _discountCtrl.text = '0';
        _notesCtrl.clear();
        _refreshRandoms();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFDC2626)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred'), backgroundColor: Color(0xFFDC2626)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitDraft() async {
    if (_items.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await OrderRepositoryImpl().createOrder(
        userName: widget.user?.fullName ?? 'Staff',
        customerName: _customerNameCtrl.text,
        customerPhone: _customerPhoneCtrl.text.isNotEmpty ? _customerPhoneCtrl.text : null,
        payMethod: _paymentMethod,
        voucherNo: 'INV-$_voucherRandom',
        orderId: 'ORD-$_orderRandom',
        items: _items,
        grandTotal: _totalPayable,
        discount: _discountPct.toInt(),
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        status: 'draft',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved successfully!'), backgroundColor: Color(0xFF2563EB)),
      );
      setState(() {
        _items.clear();
        _customerNameCtrl.text = 'Customer';
        _customerPhoneCtrl.clear();
        _discountCtrl.text = '0';
        _notesCtrl.clear();
        _refreshRandoms();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFDC2626)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred'), backgroundColor: Color(0xFFDC2626)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.subtotal);
  int get _totalItems => _items.fold(0, (s, i) => s + i.quantity);
  double get _discountPct => double.tryParse(_discountCtrl.text) ?? 0;
  double get _discountAmt => _subtotal * (_discountPct / 100);
  double get _totalPayable => _subtotal - _discountAmt;

  void _updateQty(int index, int delta) {
    setState(() {
      final newQty = _items[index].quantity + delta;
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQty;
      }
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }





  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _content(isWide);

        if (isWide) {
          return Scaffold(
            backgroundColor: kBg,
            body: Row(
              children: [
                SizedBox(
                    width: 240,
                    child: AppDrawer(user: widget.user, activeItem: 'Sale')),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: kBg,
          drawer: AppDrawer(user: widget.user, activeItem: 'Sale'),
          body: body,
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
              user: widget.user,
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
                child: TextField(
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
                Text('INV-$_voucherRandom',
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
                final result = await Navigator.of(context).push<List<SaleItem>>(
                  MaterialPageRoute(builder: (_) => const AddProductsScreen()),
                );
                if (result != null && result.isNotEmpty) {
                  setState(() => _items.addAll(result));
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
        if (_items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No items added yet.',
                  style: TextStyle(color: kGray, fontSize: 14)),
            ),
          )
        else
          ...List.generate(_items.length, (i) => _itemRow(i)),
      ],
    );
  }

  Widget _itemRow(int index) {
    final item = _items[index];
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
                    onTap: () => _removeItem(index),
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
    final qty = _items[index].quantity;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _qtyBtn(Icons.remove, () => _updateQty(index, -1)),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text('$qty',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTitle)),
          ),
          _qtyBtn(Icons.add, () => _updateQty(index, 1)),
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
          _summaryRow('Total Items', '$_totalItems'),
          const SizedBox(height: 12),
          _summaryPriceRow('Subtotal', _subtotal),
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
                  onChanged: (_) => setState(() {}),
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
          _summaryPriceRow('Discount Amount', _discountAmt),
          const Divider(height: 24, color: kBorder),
          Row(
            children: [
              const Text('Total Payable',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTitle)),
              const Spacer(),
              PriceText(_totalPayable,
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
                child: Text('ORD-$_orderRandom',
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
                      value: _paymentMethod,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'Card', child: Text('Card')),
                        DropdownMenuItem(value: 'Mobile Pay', child: Text('Mobile Pay')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _paymentMethod = v);
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
            if (_items.isEmpty) return;
            _submitDraft();
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _outlineBtn('Preview', Icons.visibility_outlined, () async {
            if (_items.isEmpty) return;
            await _loadShop();
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SalePreviewScreen(
                  customerName: _customerNameCtrl.text,
                  customerPhone: _customerPhoneCtrl.text.isNotEmpty ? _customerPhoneCtrl.text : null,
                  staffName: widget.user?.fullName ?? 'Staff',
                  voucherNo: 'INV-$_voucherRandom',
                  orderId: 'ORD-$_orderRandom',
                  dateTime: DateTime.now(),
                  items: List<SaleItem>.from(_items),
                  discountPct: _discountPct,
                  subtotal: _subtotal,
                  discountAmt: _discountAmt,
                  totalPayable: _totalPayable,
                  paymentMethod: _paymentMethod,
                  notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
                  shopName: _shop?.name,
                  shopAddress: _shop?.physicalAddress,
                  shopPhone: _shop?.ownerInformation.phone,
                  shopEmail: _shop?.ownerInformation.email,
                  shopImage: _shop?.logoData ?? _shop?.logoUrl,
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: (_isSubmitting || _items.isEmpty) ? null : _submitSale,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: (_isSubmitting || _items.isEmpty)
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                color: (_isSubmitting || _items.isEmpty) ? kGray : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting)
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
                  Text(_isSubmitting ? 'Saving...' : 'Sale',
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

  void _showPrintVoucherSettings() {
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
                          decoration: BoxDecoration(
                            color: kBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Print Voucher Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: kTitle,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(Icons.close, color: kGray),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _toggleRow(
                        icon: Icons.picture_as_pdf,
                        title: 'PDF Export',
                        subtitle: 'Export voucher as PDF file',
                        value: _pdfExportEnabled,
                        onChanged: (v) {
                          setSheetState(() => _pdfExportEnabled = v);
                          setState(() => _pdfExportEnabled = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      _toggleRow(
                        icon: Icons.receipt_long,
                        title: 'Voucher Paper',
                        subtitle: 'Print on voucher paper',
                        value: _voucherPaperEnabled,
                        onChanged: (v) {
                          setSheetState(() => _voucherPaperEnabled = v);
                          setState(() => _voucherPaperEnabled = v);
                        },
                      ),
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
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kGray, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: kGray),
                ),
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
          onTap: _showPrintVoucherSettings,
          child: _footerBtn(Icons.print_outlined, 'Print Voucher'),
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
                builder: (_) => SaleItemScreen(user: widget.user),
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
