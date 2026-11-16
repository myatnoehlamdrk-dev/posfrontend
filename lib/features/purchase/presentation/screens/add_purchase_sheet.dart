import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/purchase/presentation/viewmodels/purchase_item_view_model.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class AddPurchaseSheet extends StatefulWidget {
  final PurchaseItemViewModel viewModel;
  final VoidCallback onAddSupplier;

  const AddPurchaseSheet({
    super.key,
    required this.viewModel,
    required this.onAddSupplier,
  });

  @override
  State<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends State<AddPurchaseSheet> {
  String? _selectedSupplierId;
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _dateController = TextEditingController(
    text:
        '${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().year}',
  );
  final _notesController = TextEditingController();

  /// True while the POST is in flight. The sheet used to give no sign at all
  /// during that wait: the button looked idle on an endpoint that can take
  /// seconds to wake, so a second tap sent a second order. It now shows a
  /// spinner and refuses further taps until the answer arrives.
  bool _saving = false;

  /// What to tell the user when the save fails. The view model reports it on
  /// itself, which this sheet does not listen to, so a rejected save used to
  /// look like a tap that did nothing.
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final price = int.tryParse(_priceController.text.trim()) ?? 0;

    // Say what is missing instead of returning silently: an empty name or a
    // zero quantity used to swallow the tap with no feedback at all.
    if (name.isEmpty) {
      setState(() => _error = context.l10n.t('Enter the item name'));
      return;
    }
    if (qty <= 0) {
      setState(() => _error = context.l10n.t('Enter a quantity'));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final success = await widget.viewModel.createPurchaseItem(
      productName: name,
      quantity: qty,
      unitPrice: price,
      date: _dateController.text,
      supplierId: _selectedSupplierId,
      notes: _notesController.text,
      size: _sizeController.text,
      color: _colorController.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.pop(context);
    } else {
      setState(
        () =>
            _error =
                widget.viewModel.errorMessage ??
                context.l10n.t('Could not create the purchase order'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.t('New Purchase Order'),
                    style: TextStyle(
                      fontSize: AppTypography.titleSmallSize,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: p.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    context.l10n.t('Supplier'),
                    style: TextStyle(
                      fontSize: AppTypography.labelMediumSize,
                      fontWeight: FontWeight.w500,
                      color: p.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAddSupplier();
                    },
                    child: Text(
                      context.l10n.t('+ Add Supplier'),
                      style: TextStyle(
                        fontSize: AppTypography.labelMediumSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: p.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSupplierId,
                    hint: Text(
                      context.l10n.t('Select a supplier...'),
                      style: TextStyle(color: p.textSecondary, fontSize: AppTypography.bodySmallSize),
                    ),
                    items: widget.viewModel.suppliers
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.name,
                              style: const TextStyle(fontSize: AppTypography.bodySmallSize),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSupplierId = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _inputField(
                context,
                'Item / Product Name',
                'e.g. All-Purpose Flour (50kg)',
                _nameController,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      context,
                      'Size (optional)',
                      'e.g. Large',
                      _sizeController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(
                      context,
                      'Color (optional)',
                      'e.g. Red',
                      _colorController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      context,
                      'Quantity',
                      '0',
                      _qtyController,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(
                      context,
                      'Unit Price (MMK)',
                      '0',
                      _priceController,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _inputField(
                context,
                'Purchase Date (MM/DD/YYYY)',
                'mm/dd/yyyy',
                _dateController,
              ),
              const SizedBox(height: 16),
              _inputField(
                context,
                'Notes (optional)',
                'Any notes...',
                _notesController,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: p.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: p.dangerFg,
                      fontSize: AppTypography.labelMediumSize,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.brandPurple.withValues(
                      alpha: 0.6,
                    ),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.l10n.t('Create Purchase Order'),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.labelMediumSize,
            fontWeight: FontWeight.w500,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: p.textSecondary, fontSize: AppTypography.bodySmallSize),
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
              borderSide: const BorderSide(color: AppColors.brandPurple, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
