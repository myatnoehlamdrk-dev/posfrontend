import 'package:flutter/material.dart';
import 'package:posfrontend/features/settings/domain/entities/printer_profile.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/services/printer_connection_result.dart';
import 'package:posfrontend/shared/services/printer_connection_tester.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';

/// The models the form offers. NS06H first because it is the printer this
/// settings section exists for; the generic entry covers any other ESC/POS
/// box without needing a new release to add it.
const List<String> kPrinterModels = ['NS06H', 'Generic ESC/POS'];

/// Opens the add/edit printer sheet.
///
/// Returns `true` once a profile has been stored, `null` when dismissed.
/// The caller refreshes its list either way — one path, and a reload costs a
/// single local read.
///
/// [defaultForNew] pre-selects the default switch for the first printer a
/// shop registers, so a one-printer till never has to think about the flag.
/// [onSave] does the storing; the sheet owns only validation and UI state.
Future<bool?> showPrinterFormSheet(
  BuildContext context, {
  PrinterProfile? existing,
  required bool defaultForNew,
  required Future<void> Function(PrinterProfile profile) onSave,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PrinterFormSheet(
      existing: existing,
      defaultForNew: defaultForNew,
      onSave: onSave,
    ),
  );
}

class _PrinterFormSheet extends StatefulWidget {
  const _PrinterFormSheet({
    required this.existing,
    required this.defaultForNew,
    required this.onSave,
  });

  final PrinterProfile? existing;
  final bool defaultForNew;
  final Future<void> Function(PrinterProfile profile) onSave;

  @override
  State<_PrinterFormSheet> createState() => _PrinterFormSheetState();
}

class _PrinterFormSheetState extends State<_PrinterFormSheet> {
  // Same mid-tone brand accent the settings screen's rows resolve to.
  static const Color orange = Color(0xFFF97316);
  static const Color red = Color(0xFFEF4444);

  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late String _model;
  late String _paperSize;
  late bool _isDefault;

  bool _saving = false;
  bool _testing = false;
  String? _validationError;
  ConnectionTestResult? _testResult;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _hostController = TextEditingController(text: existing?.host ?? '');
    _portController = TextEditingController(
      text: (existing?.port ?? PrinterProfile.defaultPort).toString(),
    );
    _model = existing?.model ?? kPrinterModels.first;
    _paperSize = existing?.paperSize ?? PrinterProfile.paper58mm;
    _isDefault = existing?.isDefault ?? widget.defaultForNew;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  // Four dot-separated octets, each bounded below the 256 an octet allows.
  // Regex-then-range rather than a split-and-parse so leading zeros, empty
  // segments and trailing dots all miss the match instead of slipping through
  // to an int parse that would happily read '192.168.1.' as three numbers.
  static final RegExp _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

  bool _isValidHost(String value) {
    if (!_ipv4.hasMatch(value)) return false;
    return value.split('.').every((octet) => int.parse(octet) <= 255);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final gray = p.textSecondary;
    final title = widget.existing == null
        ? context.l10n.t('Add Printer')
        : context.l10n.t('Edit Printer');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _saving ? null : () => Navigator.pop(context),
                    child: Icon(Icons.close, color: gray),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _label(context.l10n.t('Printer Name'), gray),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                decoration: fieldDecorationFor(
                  context,
                  context.l10n.t('e.g. Counter Printer'),
                ),
                onChanged: (_) => setState(() => _validationError = null),
              ),
              const SizedBox(height: 16),
              _label(context.l10n.t('Printer Model'), gray),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: kPrinterModels
                    .map((m) => _optionTile(
                          label: m,
                          icon: m == kPrinterModels.first
                              ? Icons.print_outlined
                              : Icons.lan_outlined,
                          selected: _model == m,
                          enabled: !_saving,
                          onTap: () => setState(() {
                            _model = m;
                            _validationError = null;
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(context.l10n.t('IP Address'), gray),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hostController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: fieldDecorationFor(
                            context,
                            context.l10n.t('e.g. 192.168.1.100'),
                          ),
                          onChanged: (_) => setState(() {
                            _validationError = null;
                            _testResult = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 104,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(context.l10n.t('Port'), gray),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _portController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration: fieldDecorationFor(context, ''),
                          onChanged: (_) => setState(() {
                            _validationError = null;
                            _testResult = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label(context.l10n.t('Paper Size'), gray),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _optionTile(
                      label: PrinterProfile.paper58mm,
                      icon: Icons.crop_free,
                      selected: _paperSize == PrinterProfile.paper58mm,
                      enabled: !_saving,
                      onTap: () => setState(
                        () => _paperSize = PrinterProfile.paper58mm,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _optionTile(
                      label: PrinterProfile.paper80mm,
                      icon: Icons.aspect_ratio,
                      selected: _paperSize == PrinterProfile.paper80mm,
                      enabled: !_saving,
                      onTap: () => setState(
                        () => _paperSize = PrinterProfile.paper80mm,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star_outline, color: gray, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.t('Set as Default'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isDefault,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() {
                            _isDefault = v;
                            _validationError = null;
                          }),
                  ),
                ],
              ),
              if (PrinterConnectionTester.isSupported) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving || _testing ? null : _testConnection,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: orange,
                    side: const BorderSide(color: orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: orange,
                          ),
                        )
                      : const Icon(Icons.network_check, size: 18),
                  label: Text(context.l10n.t('Test Connection')),
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: 8),
                  _testResultLine(
                    _testResult!.ok ? p.successFg : p.dangerFg,
                  ),
                ],
              ],
              if (_validationError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _validationError!,
                  style: const TextStyle(color: red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: gray,
                        side: BorderSide(color: p.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(context.l10n.t('Cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      label: context.l10n.t('Save'),
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  /// One selectable card. Mirrors the new-sale sheet's format/paper options
  /// so a selected setting reads the same everywhere in the app.
  Widget _optionTile({
    required String label,
    required IconData icon,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? p.selectionTint : p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? orange : p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? orange : p.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? orange : p.textPrimary,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, color: orange, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _testResultLine(Color color) {
    final ok = _testResult!.ok;
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.error_outline,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            ok
                ? context.l10n.t('Printer reachable')
                : '${context.l10n.t('Could not reach the printer.')} '
                      '${_testResult!.detail}',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (!_isValidHost(host)) {
      setState(() {
        _validationError = context.l10n.t(
          'Enter a valid IP address, e.g. 192.168.1.100.',
        );
        _testResult = null;
      });
      return;
    }
    // The port is prefilled, so a bad value here means it was edited — and
    // testing the default port instead of the one on screen would report a
    // printer the form is not actually pointing at.
    if (port == null || port < 1 || port > 65535) {
      setState(() {
        _validationError = context.l10n.t(
          'Port must be between 1 and 65535.',
        );
        _testResult = null;
      });
      return;
    }
    setState(() {
      _testing = true;
      _validationError = null;
      _testResult = null;
    });
    final result = await PrinterConnectionTester.test(host, port);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());

    if (name.isEmpty) {
      setState(() {
        _validationError = context.l10n.t('Enter a printer name.');
      });
      return;
    }
    if (!_isValidHost(host)) {
      setState(() {
        _validationError = context.l10n.t(
          'Enter a valid IP address, e.g. 192.168.1.100.',
        );
      });
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      setState(() {
        _validationError = context.l10n.t(
          'Port must be between 1 and 65535.',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _validationError = null;
    });
    try {
      await widget.onSave(
        PrinterProfile(
          id: widget.existing?.id ??
              '${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          model: _model,
          host: host,
          port: port,
          paperSize: _paperSize,
          isDefault: _isDefault,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _validationError = e.toString();
      });
    }
  }
}
