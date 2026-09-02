import 'package:flutter/material.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/sale_items/model/sale_item_models.dart';

class SaleDetailScreen extends StatelessWidget {
  final SaleOrder order;
  final LoginResponse? user;

  const SaleDetailScreen({super.key, required this.order, this.user});

  static const Color teal = Color(0xFF14B8A6);
  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color green = Color(0xFF16A34A);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color orange = Color(0xFFD97706);
  static const Color orangeBg = Color(0xFFFEF3C7);

  @override
  Widget build(BuildContext context) {
    final isAlreadySale = order.status == OrderStatus.alreadySale;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderHeader(isAlreadySale),
                    const SizedBox(height: 12),
                    _buildInfoCard('Customer Information', [
                      _infoRow('Customer Name', order.customerName.isNotEmpty ? order.customerName : '-'),
                      _infoRow('Phone', order.customerPhone.isNotEmpty ? order.customerPhone : '-'),
                    ]),
                    const SizedBox(height: 12),
                    if (order.saleItems.isNotEmpty) ...[
                      _buildInfoCard('Ordered Items (${order.saleItems.length})', order.saleItems.map((item) {
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
                              const SizedBox(width: 12),
                              Text('MMK ${_formatAmount(item.subtotal)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: titleColor)),
                            ],
                          ),
                        );
                      }).toList()),
                    ] else ...[
                      _buildInfoCard('Ordered Items', [
                        _infoRow('Product', order.productName),
                        _infoRow('Description', order.description),
                        _infoRow('Quantity', 'x${order.quantity}'),
                      ]),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoCard('Payment Information', [
                      _infoRow('Payment Method', order.payMethod.isNotEmpty ? order.payMethod : 'Cash'),
                      _infoRow('Payment Status', isAlreadySale ? 'Paid' : 'Pending'),
                      _infoRow('Total Amount', 'MMK ${_formatAmount(order.amount)}'),
                    ]),
                    const SizedBox(height: 12),
                    _buildInfoCard('Order Status & History', [
                      _infoRow('Order Date', order.date),
                      _infoRow('Order Status', isAlreadySale ? 'Completed' : 'Pending'),
                      _infoRow('Voucher Ref', order.voucherNo.isNotEmpty ? '#${order.voucherNo}' : '#${order.orderId}'),
                    ]),
                    const SizedBox(height: 24),
                  ],
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
                  order.voucherNo.isNotEmpty ? order.voucherNo : 'Order #${order.orderId}',
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
            order.productName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          if (order.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(order.description, style: const TextStyle(fontSize: 13, color: gray)),
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
                  _formatDate(order.date),
                  style: const TextStyle(fontSize: 13, color: gray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'MMK ${_formatAmount(order.amount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
