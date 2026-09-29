import 'package:flutter/services.dart';

/// Restricts the discount field to whole percentages in the range 0..100.
///
/// This closes a gap between what the screen showed and what the sale recorded.
/// The field used to accept a decimal percent, which reached the view model as a
/// double and was truncated on submit, so a cashier could see `12.50%` on the
/// totals while the sale was saved with a discount of `12`. The database column
/// is an integer, so the fraction had nowhere to survive regardless.
///
/// Percentages above 100 are rejected rather than clamped. Clamping would
/// rewrite the text under the caret mid-keystroke; rejecting drops just the
/// offending keystroke, so typing `250` settles on `25` without the field
/// fighting the typist. It also keeps the payable total from going negative.
///
/// Digit filtering is left to [FilteringTextInputFormatter.digitsOnly] ahead of
/// this in the formatter chain, which handles selection offsets correctly.
/// Rejecting a keystroke by returning [oldValue] needs no such arithmetic.
class PercentInputFormatter extends TextInputFormatter {
  const PercentInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    if (raw.isEmpty) return newValue;

    final percent = int.tryParse(raw);
    if (percent != null && percent > 100) return oldValue;

    // The field starts on '0', so typing 5 would otherwise leave '05%'.
    final trimmed = raw.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final caretAtEnd = newValue.selection.baseOffset == raw.length &&
        newValue.selection.extentOffset == raw.length;
    if (trimmed == raw || !caretAtEnd) return newValue;

    return newValue.copyWith(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
  }
}
