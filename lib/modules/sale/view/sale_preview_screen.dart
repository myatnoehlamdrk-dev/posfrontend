import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:posfrontend/modules/sale/model/sale_models.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

String _fmtPrice(double value) {
  final v = value.round();
  final neg = v < 0;
  final digits = v.abs().toString();
  final withCommas = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '${neg ? '-' : ''}$withCommas';
}

class SalePreviewScreen extends StatelessWidget {
  final String customerName;
  final String? customerPhone;
  final String staffName;
  final String voucherNo;
  final String orderId;
  final DateTime dateTime;
  final List<SaleItem> items;
  final double discountPct;
  final double subtotal;
  final double discountAmt;
  final double totalPayable;
  final String paymentMethod;
  final String? notes;
  final String? shopName;
  final String? shopAddress;
  final String? shopPhone;
  final String? shopEmail;
  final String? shopImage;

  const SalePreviewScreen({
    super.key,
    required this.customerName,
    this.customerPhone,
    required this.staffName,
    required this.voucherNo,
    required this.orderId,
    required this.dateTime,
    required this.items,
    required this.discountPct,
    required this.subtotal,
    required this.discountAmt,
    required this.totalPayable,
    required this.paymentMethod,
    this.notes,
    this.shopName,
    this.shopAddress,
    this.shopPhone,
    this.shopEmail,
    this.shopImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTitle),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Invoice Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTitle)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: kPurple),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
                boxShadow: const [
                  BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _header(),
                  _divider(),
                  _invoiceInfo(),
                  _divider(),
                  _customerSection(),
                  _divider(),
                  _itemsHeader(),
                  _itemsList(),
                  _divider(),
                  _summarySection(),
                  if (notes != null && notes!.isNotEmpty) _notesSection(),
                  _footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          if (shopImage != null && shopImage!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: shopImage!.startsWith('http')
                  ? Image.network(
                      shopImage!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _shopPlaceholder(),
                    )
                  : _base64Image(shopImage!),
            )
          else
            _shopPlaceholder(),
          const SizedBox(height: 10),
          if (shopName != null && shopName!.isNotEmpty)
            Text(
              shopName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (shopName != null && shopName!.isNotEmpty) const SizedBox(height: 4),
          if (shopAddress != null && shopAddress!.isNotEmpty)
            Text(
              shopAddress!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          if (shopPhone != null && shopPhone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                shopPhone!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
          if (shopEmail != null && shopEmail!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                shopEmail!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'INVOICE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            voucherNo,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: kBorder),
    );
  }

  Widget _invoiceInfo() {
    final dateStr = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final h = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final m = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$h:$m $ampm';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _infoRow('Voucher ID', voucherNo),
          const SizedBox(height: 8),
          _infoRow('Order ID', orderId),
          const SizedBox(height: 8),
          _infoRow('Date', dateStr),
          const SizedBox(height: 8),
          _infoRow('Time', timeStr),
          const SizedBox(height: 8),
          _infoRow('Staff', staffName),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: kGray)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTitle)),
      ],
    );
  }

  Widget _customerSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: kPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer', style: TextStyle(fontSize: 11, color: kGray)),
                const SizedBox(height: 2),
                Text(customerName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTitle)),
                if (customerPhone != null && customerPhone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(customerPhone!,
                      style: const TextStyle(fontSize: 12, color: kGray)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Expanded(
            flex: 4,
            child: Text('Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGray)),
          ),
          const Expanded(
            flex: 1,
            child: Text('Qty', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGray)),
          ),
          const Expanded(
            flex: 2,
            child: Text('Price', textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGray)),
          ),
          const Expanded(
            flex: 2,
            child: Text('Total', textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGray)),
          ),
        ],
      ),
    );
  }

  Widget _itemsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final variant = [
            if (item.size != null && item.size != 'Regular') item.size,
            if (item.color != null && item.color!.isNotEmpty) item.color,
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: i < items.length - 1
                ? const BoxDecoration(
                    border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
                  )
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTitle)),
                      if (variant.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(variant,
                            style: const TextStyle(fontSize: 11, color: kGray)),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text('${item.quantity}', textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: kTitle)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_fmtPrice(item.unitPrice), textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, color: kTitle)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_fmtPrice(item.subtotal), textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTitle)),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _summarySection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _summaryRow('Subtotal', subtotal),
          if (discountPct > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount ($discountPct%)',
                    style: const TextStyle(fontSize: 13, color: kGray)),
                Text('-${_fmtPrice(discountAmt)}', textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kRed)),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: DashedDivider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payable',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTitle)),
              Text(_fmtPrice(totalPayable), textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Method', style: TextStyle(fontSize: 13, color: kGray)),
                Text(paymentMethod,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPurple)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: kGray)),
        Text(_fmtPrice(amount), textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTitle)),
      ],
    );
  }

  Widget _notesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF9C3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notes',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
            const SizedBox(height: 4),
            Text(notes!, style: const TextStyle(fontSize: 12, color: Color(0xFF78350F))),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 32),
          const SizedBox(height: 8),
          const Text('Thank you for your purchase!',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTitle)),
          const SizedBox(height: 4),
          Text('Total Items: ${items.length}',
              style: const TextStyle(fontSize: 12, color: kGray)),
        ],
      ),
    );
  }

  Widget _shopPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.store, color: Colors.white, size: 32),
    );
  }

  Widget _base64Image(String data) {
    try {
      Uint8List bytes = base64Decode(data);
      return Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover);
    } catch (_) {
      return _shopPlaceholder();
    }
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 4.0;
        final dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: 4,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: kBorder)),
            );
          }),
        );
      },
    );
  }
}
