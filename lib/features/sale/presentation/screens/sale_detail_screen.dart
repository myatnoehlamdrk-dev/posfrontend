import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/presentation/screens/new_sale_screen.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';


class SaleDetailScreen extends StatefulWidget {
  final SaleOrderEntity order;

  const SaleDetailScreen({super.key, required this.order});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late SaleOrderEntity _order;

  static const Color teal = Color(0xFF14B8A6);
  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color green = Color(0xFF16A34A);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color orange = Color(0xFFD97706);
  static const Color orangeBg = Color(0xFFFEF3C7);

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadySale = _order.status == OrderStatus.alreadySale;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {},
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderHeader(isAlreadySale),
                      const SizedBox(height: 12),
                       _buildInfoCard('Customer Information', [
                         _infoRow('Customer Name', _order.customerName.isNotEmpty ? _order.customerName : '-'),
                         _infoRow('Phone', _order.customerPhone.isNotEmpty ? _order.customerPhone : '-'),
                         if (_order.customerLocation.isNotEmpty)
                           _infoRow('Location', _order.customerLocation),
                       ]),
                       const SizedBox(height: 12),
                       if (_order.createdBy.isNotEmpty)
                         _buildInfoCard('Saler Information', [
                           _infoRow('Saler Name', _order.createdBy),
                           if (_order.createdAt.isNotEmpty)
                             _infoRow('Created At', _formatDate(_order.createdAt)),
                         ]),
                       const SizedBox(height: 12),
                      if (_order.saleItems.isNotEmpty) ...[
                        _buildInfoCard('Ordered Items (${_order.saleItems.length})', _order.saleItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: titleColor)),
                                      if (item.size.isNotEmpty || item.color.isNotEmpty)
                                        Text(
                                          [if (item.size.isNotEmpty) 'Size: ${item.size}', if (item.color.isNotEmpty) 'Color: ${item.color}'].join(' | '),
                                          style: const TextStyle(fontSize: 11, color: gray),
                                        ),
                                    ],
                                  ),
                                ),
                                Text('x${item.quantity}', style: const TextStyle(fontSize: 12, color: gray)),
                                const SizedBox(width: 8),
                                PriceText(item.subtotal.toDouble(), maxLength: 14, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: titleColor)),
                              ],
                            ),
                          );
                        }).toList()),
                      ] else ...[
                        _buildInfoCard('Ordered Items', [
                          _infoRow('Product', _order.productName),
                          _infoRow('Description', _order.description),
                          _infoRow('Quantity', 'x${_order.quantity}'),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      _buildInfoCard('Payment Information', [
                        _infoRow('Payment Method', _order.payMethod.isNotEmpty ? _order.payMethod : 'Cash'),
                        _infoRow('Payment Status', isAlreadySale ? 'Paid' : 'Pending'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontSize: 13, color: gray)),
                            const SizedBox(width: 12),
                            Flexible(
                              child: PriceText(_order.amount.toDouble(), maxLength: 14, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: titleColor)),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildInfoCard('Order Status & History', [
                        _infoRow('Order Date', _formatDate(_order.date)),
                        _infoRow('Order Status', isAlreadySale ? 'Completed' : 'Pending'),
                        _infoRow('Voucher Ref', _order.voucherNo.isNotEmpty ? '#${_order.voucherNo}' : '#${_order.orderId}'),
                      ]),
                      if (_order.createdBy.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard('Audit Information', [
                          if (_order.createdBy.isNotEmpty)
                            _infoRow('Created By', _order.createdBy),
                          if (_order.createdAt.isNotEmpty)
                            _infoRow('Created At', _formatDate(_order.createdAt)),
                          if (_order.updatedAt.isNotEmpty)
                            _infoRow('Updated At', _formatDate(_order.updatedAt)),
                        ]),
                      ],
                      if (!isAlreadySale) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _upToSale,
                            icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                            label: const Text('Up to Sale'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D28D9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: titleColor),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Sale Detail',
                style: TextStyle(
                  color: titleColor,
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

  Widget _buildOrderHeader(bool isAlreadySale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _order.voucherNo.isNotEmpty ? _order.voucherNo : 'Order #${_order.orderId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAlreadySale ? greenBg : orangeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAlreadySale ? 'Already Sale' : 'Will Be Sale',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAlreadySale ? green : orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _order.productName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          if (_order.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_order.description, style: const TextStyle(fontSize: 13, color: gray)),
          ],
          const SizedBox(height: 12),
          const Divider(color: border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: gray),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatDate(_order.date),
                  style: const TextStyle(fontSize: 13, color: gray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: PriceText(
                  _order.amount.toDouble(),
                  maxLength: 14,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: teal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: gray)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _upToSale() {
    final saleItems = _order.saleItems
        .where((item) => item.productId.isNotEmpty)
        .map((item) => SaleItemEntity(
              productId: item.productId,
              productName: item.productName,
              unitPrice: item.unitPrice.toDouble(),
              quantity: item.quantity,
              size: item.size.isNotEmpty ? item.size : null,
              color: item.color.isNotEmpty ? item.color : null,
            ))
        .toList();

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => NewSaleScreen(
          initialItems: saleItems,
          initialCustomerName: _order.customerName,
          initialCustomerPhone: _order.customerPhone,
          initialPaymentMethod: _order.payMethod,
          existingOrderId: _order.orderId,
        ),
      ),
    )
        .then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return dt.toFormattedDateTime();
    } catch (_) {
      return dateStr;
    }
  }
}
