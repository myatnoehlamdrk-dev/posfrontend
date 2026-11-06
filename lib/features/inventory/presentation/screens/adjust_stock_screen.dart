import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/inventory/domain/entities/inventory_store_item.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_message.dart';

class AdjustStockScreen extends StatefulWidget {
  final InventoryStoreItem item;
  const AdjustStockScreen({super.key, required this.item});

  @override
  State<AdjustStockScreen> createState() => _AdjustStockScreenState();
}

class _AdjustStockScreenState extends State<AdjustStockScreen> {
  bool _add = true;
  int _qty = 1;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _current => widget.item.quantityOnHand;
  int get _newStock => _add ? _current + _qty : _current - _qty;

  bool get _valid {
    if (_qty <= 0) return false;
    if (!_add && _qty > _current) return false;
    if (_newStock < 0) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.t('INVENTORY ADJUSTMENT'),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: Color(0xFF008F85),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.t('Update stock'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        color: p.chipBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 14, color: p.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    // Product card
                    Container(
                      height: 79,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.chipBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: p.chipBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.inventory_2_outlined, size: 24, color: p.textSecondary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: p.textPrimary,
                                  ),
                                ),
                                Text(
                                  widget.item.sku,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: p.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      height: 16,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5F7EF),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          SizedBox(width: 5, height: 5),
                                          SizedBox(width: 3),
                                          Text(
                                            'In stock',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF087A50),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_current.withCommas()} units',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Adjustment type
                    Text(
                      context.l10n.t('Adjustment type'),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: _typeButton(
                            p: p,
                            label: context.l10n.t('Add stock'),
                            icon: Icons.arrow_upward,
                            selected: _add,
                            onTap: () => setState(() => _add = true),
                            selectedBg: const Color(0xFFE8F7F0),
                            selectedBorder: const Color(0xFF15966B),
                            selectedFg: const Color(0xFF087A50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _typeButton(
                            p: p,
                            label: context.l10n.t('Remove stock'),
                            icon: Icons.arrow_downward,
                            selected: !_add,
                            selectedBg: const Color(0xFFFCE8E5),
                            selectedBorder: const Color(0xFFD94B3D),
                            selectedFg: const Color(0xFFC43F35),
                            onTap: () => setState(() => _add = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quantity
                    Text(
                      context.l10n.t('Quantity'),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFFD7E1DB)),
                      ),
                      child: Row(
                        children: [
                          _qtyBtn(
                            bg: p.chipBg,
                            icon: Icons.remove,
                            color: p.textSecondary,
                            onTap: () {
                              if (_qty > 1) setState(() => _qty--);
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '$_qty',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          _qtyBtn(
                            bg: const Color(0xFFE8F7F0),
                            icon: Icons.add,
                            color: const Color(0xFF15966B),
                            onTap: () => setState(() => _qty++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFFDDE5E1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.t('Current stock'),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: p.textSecondary,
                                ),
                              ),
                              Text(
                                _current.withCommas(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: p.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 12, color: p.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.t('New stock level'),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary,
                                ),
                              ),
                              Text(
                                '${_newStock.withCommas()} units',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Reason
                    Row(
                      children: [
                        Text(
                          context.l10n.t('Reason or note'),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                          ),
                        ),
                        Text(
                          ' (optional)',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 58,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFFD7E1DB)),
                      ),
                      child: TextField(
                        controller: _noteCtrl,
                        maxLines: 3,
                        style: TextStyle(fontSize: 9, color: p.textPrimary),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: context.l10n.t('e.g. Cycle count correction'),
                          hintStyle: TextStyle(
                            fontSize: 9,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              height: 59,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: const Color(0xFFE5EBE7))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 37,
                child: ElevatedButton.icon(
                  onPressed: _valid
                      ? () async {
                          final navigator = Navigator.of(context);
                          final msg = context.l10n.t('Stock adjustment saved.');
                          try {
                            await ApiClient.instance.post(
                              '/inventory-stores/${widget.item.id}/adjust',
                              data: {
                                'type': _add ? 'add' : 'remove',
                                'quantity': _qty,
                                if (_noteCtrl.text.trim().isNotEmpty)
                                  'note': _noteCtrl.text.trim(),
                              },
                            );
                            if (!mounted) return;
                            showSuccessMessage(context, msg);
                            navigator.pop(true);
                          } catch (e) {
                            if (mounted) showErrorMessage(context, e);
                          }
                        }
                      : null,
                  icon: const Icon(Icons.check, size: 14),
                  label: Text(
                    context.l10n.t('Save adjustment'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14241E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton({
    required AppPalette p,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required Color selectedBg,
    required Color selectedBorder,
    required Color selectedFg,
  }) {
    final bg = selected ? selectedBg : p.surface;
    final border = selected ? selectedBorder : const Color(0xFFDDE5E1);
    final fg = selected ? selectedFg : p.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn({
    required Color bg,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

