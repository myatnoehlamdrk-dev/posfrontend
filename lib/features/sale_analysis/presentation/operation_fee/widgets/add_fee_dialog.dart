import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee_models.dart';
import '../operation_fee_style.dart';

/// Modal form used to create a new operation fee rule.
class AddFeeDialog extends StatefulWidget {
  /// `true` when hosted in a bottom sheet instead of a centred dialog.
  final bool asSheet;

  const AddFeeDialog({super.key, this.asSheet = false});

  @override
  State<AddFeeDialog> createState() => _AddFeeDialogState();
}

class _AddFeeDialogState extends State<AddFeeDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  FeeCalculation _calculation = FeeCalculation.fixedPerMonth;
  String? _nameError;
  String? _rateError;

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final rateText = _rateController.text.trim();
    final rate = double.tryParse(rateText.replaceAll(',', ''));

    setState(() {
      _nameError = name.isEmpty ? 'Fee name is required' : null;
      if (rateText.isEmpty) {
        _rateError = 'Rate is required';
      } else if (rate == null || rate < 0) {
        _rateError = 'Rate must be zero or greater';
      } else {
        _rateError = null;
      }
    });

    if (_nameError != null || _rateError != null) return;

    final fee = OperationFee(
      id: 'fee-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      category: FeeCategory.other,
      calculation: _calculation,
      rate: rate!,
      isActive: true,
      icon: FeeIcon.other,
      tint: FeeTint.gray,
    );
    Navigator.of(context).pop(fee);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = widget.asSheet
        ? const BorderRadius.vertical(top: Radius.circular(16))
        : BorderRadius.circular(14);

    return Container(
      width: widget.asSheet ? double.infinity : 460,
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: radius,
        border: Border.all(color: p.border),
      ),
      child: SingleChildScrollView(
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
                        'Add operation fee',
                        style: ofText(
                          size: 17,
                          weight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a new cost rule for your shop.',
                        style: ofText(
                          size: 12,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: p.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FieldLabel('Fee name', p: p),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: ofText(size: 13, color: p.textPrimary),
              decoration: _inputDecoration(
                context,
                hint: 'e.g. Business insurance',
                error: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel('Calculation method', p: p),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FeeCalculation>(
                  value: _calculation,
                  isExpanded: true,
                  isDense: true,
                  borderRadius: BorderRadius.circular(8),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: p.textSecondary,
                  ),
                  style: ofText(size: 13, color: p.textPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  items: [
                    for (final method in FeeCalculation.values)
                      DropdownMenuItem(
                        value: method,
                        child: Text(method.label),
                      ),
                  ],
                  onChanged: (m) {
                    if (m != null) setState(() => _calculation = m);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(
              _calculation.isPercentage ? 'Percentage' : 'Amount',
              p: p,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _rateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: ofText(size: 13, color: p.textPrimary),
              decoration: _inputDecoration(
                context,
                hint: '0.00',
                error: _rateError,
                prefix: _calculation.isPercentage ? null : 'MMK ',
                suffix: _calculation.isPercentage ? '%' : null,
              ),
              onChanged: (_) {
                if (_rateError != null) setState(() => _rateError = null);
              },
            ),
            const SizedBox(height: 24),
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
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: p.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add fee rule',
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
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    String? error,
    String? prefix,
    String? suffix,
  }) {
    final p = context.palette;
    return InputDecoration(
      hintText: hint,
      hintStyle: ofText(size: 12.5, color: p.textMuted),
      errorText: error,
      errorStyle: ofText(size: 10.5, color: p.dangerFg),
      isDense: true,
      filled: true,
      fillColor: p.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      prefixText: prefix,
      suffixText: suffix,
      prefixStyle: ofText(size: 12.5, color: p.textMuted),
      suffixStyle: ofText(size: 12.5, color: p.textMuted),
      border: _outline(p.border),
      enabledBorder: _outline(p.border),
      focusedBorder: _outline(p.primary),
    );
  }

  OutlineInputBorder _outline(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final AppPalette p;

  const _FieldLabel(this.text, {required this.p});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: ofText(
        size: 11.5,
        weight: FontWeight.w600,
        color: p.textSecondary,
      ),
    );
  }
}
