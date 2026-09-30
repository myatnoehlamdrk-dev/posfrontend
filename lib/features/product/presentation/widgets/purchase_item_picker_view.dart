import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';
import 'package:posfrontend/features/purchase/presentation/viewmodels/purchase_item_view_model.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

/// Second page of the add-product flow: search the purchase items and pick one
/// to seed the product form with.
class PurchaseItemPickerView extends StatefulWidget {
  final ValueChanged<PurchaseOrderEntity> onSelected;

  const PurchaseItemPickerView({super.key, required this.onSelected});

  @override
  State<PurchaseItemPickerView> createState() => _PurchaseItemPickerViewState();
}

class _PurchaseItemPickerViewState extends State<PurchaseItemPickerView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final PurchaseItemViewModel _vm = PurchaseItemViewModel();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm.loadPurchaseItems(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  List<PurchaseOrderEntity> get _filtered {
    final q = _query.trim().toLowerCase();
    // Only pending items are consumable — creating the product from one marks
    // it completed, so anything already converted is not offered again.
    final pending = _vm.purchaseItems
        .where((o) => o.status == PurchaseStatus.pending)
        .toList();
    if (q.isEmpty) return pending;
    return pending
        .where(
          (o) =>
              o.productName.toLowerCase().contains(q) ||
              o.supplierName.toLowerCase().contains(q) ||
              o.orderId.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: context.l10n.t(
                  'Search by product, supplier or order id',
                ),
                hintStyle: TextStyle(color: p.textSecondary, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: p.textSecondary,
                  size: 20,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: Icon(
                          Icons.close,
                          color: p.textSecondary,
                          size: 18,
                        ),
                      ),
                filled: true,
                fillColor: p.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.teal),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_vm.isLoading && _vm.purchaseItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.teal),
                ),
              )
            else if (_vm.errorMessage != null && _vm.purchaseItems.isEmpty)
              _errorState(p)
            else if (_filtered.isEmpty)
              _emptyState(p)
            else
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200) {
                      _vm.loadPurchaseItems();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _orderCard(_filtered[i], p),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _errorState(AppPalette p) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            _vm.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _vm.loadPurchaseItems(refresh: true),
            child: Text(context.l10n.t('Retry')),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppPalette p) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.teal,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            _query.isEmpty
                ? 'No pending purchase items'
                : 'No pending item matches "$_query"',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(PurchaseOrderEntity order, AppPalette p) {
    return InkWell(
      onTap: () => widget.onSelected(order),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.selectionTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: AppColors.teal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    order.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (order.supplierName.isNotEmpty) order.supplierName,
                      'Qty ${order.quantity}',
                      if (order.date.isNotEmpty) order.date,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PriceText(
              order.unitPrice.toDouble(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: p.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
