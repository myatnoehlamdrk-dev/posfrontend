import 'package:flutter/material.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/sale_items/model/sale_item_models.dart';
import 'package:posfrontend/modules/sale_items/viewmodel/sale_item_view_model.dart';
import 'package:posfrontend/modules/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class SaleDetailScreen extends StatefulWidget {
  final SaleOrder order;
  final LoginResponse? user;
  final SaleItemViewModel viewModel;

  const SaleDetailScreen({super.key, required this.order, required this.viewModel, this.user});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late SaleOrder _order;

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

  void _confirmDeleteItem(SaleItemDetail item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Item', style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
        content: Text(
          'Are you sure you want to delete "${item.productName}"?',
          style: const TextStyle(color: gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: gray)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updatedOrder = await widget.viewModel.deleteSaleItem(_order.orderId, item.id);
              if (mounted) {
                if (updatedOrder != null) {
                  setState(() => _order = updatedOrder);
                  showSuccessSnackBar(context, 'Item deleted');
                } else {
                  showErrorSnackBar(context, 'Failed to delete item');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _confirmDeleteItem(item),
                                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                ),
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
                        _infoRow('Order Date', _order.date),
                        _infoRow('Order Status', isAlreadySale ? 'Completed' : 'Pending'),
                        _infoRow('Voucher Ref', _order.voucherNo.isNotEmpty ? '#${_order.voucherNo}' : '#${_order.orderId}'),
                      ]),
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
