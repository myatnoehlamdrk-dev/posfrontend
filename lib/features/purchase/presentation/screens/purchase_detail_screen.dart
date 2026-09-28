import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/datetime_extensions.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';
import 'package:posfrontend/shared/widgets/custom_back_button.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final PurchaseOrder order;

  const PurchaseDetailScreen({super.key, required this.order});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  late PurchaseOrder _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isCompleted = _order.status == PurchaseStatus.completed;

    return Scaffold(
      backgroundColor: p.scaffoldBg,
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
                      _buildOrderHeader(context, isCompleted),
                      const SizedBox(height: 12),
                      _buildInfoCard(context, 'Purchaser Information', [
                        if (_order.createdBy.isNotEmpty)
                          _infoRow(context, 'Purchaser Name', _order.createdBy),
                        if (_order.createdAt.isNotEmpty)
                          _infoRow(context, 'Created At', _formatDate(_order.createdAt)),
                        if (_order.updatedBy.isNotEmpty)
                          _infoRow(context, 'Updated By', _order.updatedBy),
                        if (_order.updatedAt.isNotEmpty)
                          _infoRow(context, 'Updated At', _formatDate(_order.updatedAt)),
                      ]),
                      const SizedBox(height: 12),
                      _buildInfoCard(context, 'Supplier Information', [
                        _infoRow(
                          context,
                          'Supplier Name',
                          _order.supplierName.isNotEmpty
                              ? _order.supplierName
                              : '-',
                        ),
                        _infoRow(
                          context,
                          'Supplier ID',
                          _order.supplierId.isNotEmpty
                              ? _order.supplierId
                              : '-',
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildInfoCard(context, 'Product Details', [
                        _infoRow(
                          context,
                          'Product Name',
                          _order.productName.isNotEmpty
                              ? _order.productName
                              : '-',
                        ),
                        _infoRow(context, 'Quantity', 'x${_order.quantity}'),
                        _infoRow(
                          context,
                          'Unit Price',
                          'MMK ${_order.unitPrice.withCommas()}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: TextStyle(fontSize: 13, color: p.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: PriceText(
                                _order.totalAmount.toDouble(),
                                maxLength: 14,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: p.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ]),
                      if (_order.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(context, 'Notes', [
                          Text(
                            _order.notes,
                            style: TextStyle(
                              fontSize: 13,
                              color: p.textPrimary,
                            ),
                          ),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      _buildInfoCard(context, 'Order Status & History', [
                        _infoRow(context, 'Order Date', _formatDate(_order.date)),
                        _infoRow(
                          context,
                          'Order Status',
                          isCompleted ? 'Completed' : 'Pending',
                        ),
                        _infoRow(context, 'Order ID', '#${_order.orderId}'),
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
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border, width: 1)),
      ),
      child: Row(
        children: [
          const CustomBackButton(),
          Expanded(
            child: Center(
              child: Text(
                'Purchase Detail',
                style: TextStyle(
                  color: p.textPrimary,
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

  Widget _buildOrderHeader(BuildContext context, bool isCompleted) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCompleted ? p.successBg : p.warningBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppColors.green : AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _order.productName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: p.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatDate(_order.date),
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
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
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: p.textSecondary)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: p.textPrimary,
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
