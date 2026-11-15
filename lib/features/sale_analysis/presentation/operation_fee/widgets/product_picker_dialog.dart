import 'dart:async';

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee_models.dart';
import '../operation_fee_style.dart';

/// Centred search dialog used to pick the product shown in the impact preview.
///
/// Results come from the shop's own product search, so any product can be
/// previewed — not just the month's best seller.
class ProductPickerDialog extends StatefulWidget {
  final Future<List<OperationFeeProductOption>> Function(String query) search;
  final String? selectedProductId;

  const ProductPickerDialog({
    super.key,
    required this.search,
    this.selectedProductId,
  });

  @override
  State<ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<ProductPickerDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<OperationFeeProductOption> _results = const [];
  OperationFeeProductOption? _selected;
  Timer? _debounce;
  int _request = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    // Keeps the clear icon in sync while the debounce waits to search.
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(value.trim());
    });
  }

  Future<void> _runSearch(String query) async {
    final request = ++_request;
    if (mounted) setState(() => _loading = true);

    final results = await widget.search(query);

    // An older, slower request must not overwrite the newest query's results.
    if (!mounted || request != _request) return;

    setState(() {
      _loading = false;
      _results = results;

      // Preselect whatever the preview was already showing so reopening the
      // picker keeps the user's product highlighted.
      if (_selected == null && widget.selectedProductId != null) {
        for (final product in results) {
          if (product.id == widget.selectedProductId) {
            _selected = product;
            break;
          }
        }
      }
    });
  }

  void _select(OperationFeeProductOption product) {
    setState(() => _selected = product);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final listHeight = (MediaQuery.sizeOf(context).height * 0.45).clamp(
      200.0,
      360.0,
    );

    return Container(
      width: 480,
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose product',
                      style: ofText(
                        size: 17,
                        weight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search any product to preview how fees affect it.',
                      style: ofText(size: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 20, color: p.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            style: ofText(size: 13, color: p.textPrimary),
            onChanged: _onQueryChanged,
            onSubmitted: (_) {
              final selected = _selected;
              if (selected != null) Navigator.of(context).pop(selected);
            },
            decoration: InputDecoration(
              hintText: 'Search by name, SKU or brand',
              hintStyle: ofText(size: 12.5, color: p.textMuted),
              isDense: true,
              filled: true,
              fillColor: p.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              prefixIcon: Icon(Icons.search, size: 18, color: p.textMuted),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : InkWell(
                      onTap: () {
                        _controller.clear();
                        _runSearch('');
                      },
                      child: Icon(Icons.clear, size: 16, color: p.textMuted),
                    ),
              border: _outline(p.border),
              enabledBorder: _outline(p.border),
              focusedBorder: _outline(p.primary),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(height: listHeight, child: _resultsArea(p)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.textPrimary,
                    side: BorderSide(color: p.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: ofText(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Use product',
                    style: ofText(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultsArea(AppPalette p) {
    if (_loading && _results.isEmpty) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: p.primary),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No products found',
          style: ofText(size: 12, color: p.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final product = _results[index];
        final selected = product.id == _selected?.id;

        return InkWell(
          onTap: () => _select(product),
          onDoubleTap: () => Navigator.of(context).pop(product),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? p.selectionTint : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected ? p.primary.withValues(alpha: 0.45) : p.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: p.chipBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ofText(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(product),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ofText(size: 10.5, color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 17, color: p.primary),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _subtitle(OperationFeeProductOption product) {
    final parts = <String>[
      if (product.sku.isNotEmpty) 'SKU: ${product.sku}',
      if (product.brand.isNotEmpty) product.brand,
    ];
    return parts.isEmpty ? 'No SKU' : parts.join(' · ');
  }

  OutlineInputBorder _outline(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
  }
}
