import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final PurchaseOrder order;

  const PurchaseDetailScreen({super.key, required this.order});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  late PurchaseOrder _order;

  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color green = Color(0xFF16A34A);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color orange = Color(0xFFD97706);
  static const Color orangeBg = Color(0xFFFEF3C7);
  static const Color teal = Color(0xFF14B8A6);

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _order.status == PurchaseStatus.completed;

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
                      _buildOrderHeader(isCompleted),
                      const SizedBox(height: 12),
                      _buildInfoCard('Purchaser Information', [
                        if (_order.createdBy.isNotEmpty)
                          _infoRow('Purchaser Name', _order.createdBy),
                        if (_order.createdAt.isNotEmpty)
                          _infoRow('Created At', _formatDate(_order.createdAt)),
                        if (_order.updatedBy.isNotEmpty)
                          _infoRow('Updated By', _order.updatedBy),
                        if (_order.updatedAt.isNotEmpty)
                          _infoRow('Updated At', _formatDate(_order.updatedAt)),
                      ]),
                      const SizedBox(height: 12),
                      _buildInfoCard('Supplier Information', [
                        _infoRow(
                          'Supplier Name',
                          _order.supplierName.isNotEmpty
                              ? _order.supplierName
                              : '-',
                        ),
                        _infoRow(
                          'Supplier ID',
                          _order.supplierId.isNotEmpty
                              ? _order.supplierId
                              : '-',
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildInfoCard('Product Details', [
                        _infoRow(
                          'Product Name',
                          _order.productName.isNotEmpty
                              ? _order.productName
                              : '-',
                        ),
                        _infoRow('Quantity', 'x${_order.quantity}'),
                        _infoRow(
                          'Unit Price',
                          'MMK ${_order.unitPrice.withCommas()}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(fontSize: 13, color: gray),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: PriceText(
                                _order.totalAmount.toDouble(),
                                maxLength: 14,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: titleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ]),
                      if (_order.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard('Notes', [
                          Text(
                            _order.notes,
                            style: const TextStyle(
                              fontSize: 13,
                              color: titleColor,
                            ),
                          ),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      _buildInfoCard('Order Status & History', [
                        _infoRow('Order Date', _formatDate(_order.date)),
                        _infoRow(
                          'Order Status',
                          isCompleted ? 'Completed' : 'Pending',
                        ),
                        _infoRow('Order ID', '#${_order.orderId}'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          const CustomBackButton(),
          const Expanded(
            child: Center(
              child: Text(
                'Purchase Detail',
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

  Widget _buildOrderHeader(bool isCompleted) {
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
                  'Order #${_order.orderId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCompleted ? greenBg : orangeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? green : orange,
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
                  _order.totalAmount.toDouble(),
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
      return dt.toFormattedDateTime();
    } catch (_) {
      return dateStr;
    }
  }
}
