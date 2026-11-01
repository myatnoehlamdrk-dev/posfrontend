import 'package:flutter/material.dart';
import 'package:posfrontend/features/settings/data/printer_profile_store.dart';
import 'package:posfrontend/features/settings/domain/entities/printer_profile.dart';
import 'package:posfrontend/features/settings/presentation/widgets/printer_form_sheet.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/gradient_button.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

/// Where the shop registers its network printers — the NS06H's IP, its port
/// and the roll it carries.
///
/// The screen reads and writes exclusively through [PrinterProfileStore];
/// there is no server round trip, so the list is correct the instant a sheet
/// closes and works with the backend down.
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  static const Color orange = Color(0xFFF97316);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PrinterProfileStore _store = PrinterProfileStore();

  /// `null` until the first read finishes, so the list can tell "still
  /// loading" from "loaded empty" instead of flashing the empty state.
  List<PrinterProfile>? _printers;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final printers = await _store.load();
    if (!mounted) return;
    setState(() => _printers = printers);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final printers = _printers;

    return AppShell(
      active: DrawerDestination.setting,
      scaffoldKey: _scaffoldKey,
      backgroundColor: p.scaffoldBg,
      wrap: (_, shell) => shell,
      body: (context, isWide) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t('Printer Settings'),
              // Pushed from Settings, so back is the only way out that makes
              // sense — a hamburger would offer the drawer over the screen the
              // user just came from.
              showBackButton: true,
              showMenuButton: false,
            ),
            Expanded(
              child: RefreshableBody(
                onRefresh: _refresh,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GradientButton(
                        label: context.l10n.t('Add Printer'),
                        icon: Icons.add,
                        onPressed: () => _openForm(),
                      ),
                      const SizedBox(height: 20),
                      if (printers == null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: orange,
                              ),
                            ),
                          ),
                        )
                      else if (printers.isEmpty) ...[
                        _emptyState(),
                      ] else
                        ...printers.map(_printerCard),
                      const SizedBox(height: 8),
                      _hintBox(),
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

  Widget _emptyState() {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.print_outlined, size: 52, color: p.textMuted),
            const SizedBox(height: 14),
            Text(
              context.l10n.t('No printers saved yet.'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: p.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.t('Add your WiFi thermal printer to get started.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _printerCard(PrinterProfile printer) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        // The default is outlined rather than filled: one card in the list is
        // the state the whole app depends on, and a tinted border is the
        // cheapest way to say which one without competing with the brand fill.
        border: Border.all(color: printer.isDefault ? orange : p.border),
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
          InkWell(
            onTap: () => _openForm(existing: printer),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: printer.isDefault
                        ? orange.withValues(alpha: 0.12)
                        : p.chipBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.print_outlined,
                    color: printer.isDefault ? orange : p.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${printer.model} • ${printer.host}:${printer.port}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (printer.isDefault) _defaultBadge(p.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _paperChip(printer.paperSize),
              const Spacer(),
              if (!printer.isDefault)
                TextButton(
                  onPressed: () => _makeDefault(printer),
                  style: TextButton.styleFrom(
                    foregroundColor: orange,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(context.l10n.t('Set as Default')),
                ),
              IconButton(
                onPressed: () => _openForm(existing: printer),
                tooltip: context.l10n.t('Edit'),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: p.textSecondary,
                ),
              ),
              IconButton(
                onPressed: () => _confirmDelete(printer),
                tooltip: context.l10n.t('Delete'),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _defaultBadge(Color labelColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 13, color: orange),
          const SizedBox(width: 4),
          Text(
            context.l10n.t('Default'),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paperChip(String paperSize) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        paperSize,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: p.textSecondary,
        ),
      ),
    );
  }

  /// What this feature does, in one place. The profile is the address the
  /// till's own print job is sent to when Wi-Fi is the chosen output — no
  /// system-side registration is involved anymore — and the one step that is
  /// invisible from inside the app is said here rather than discovered at
  /// the till.
  Widget _hintBox() {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: p.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.t(
                'The app saves printer details here. With Wi-Fi chosen in '
                'Print Settings, sales print straight to this printer — the '
                'print dialog fallback uses the printer your system already '
                'knows.',
              ),
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm({PrinterProfile? existing}) async {
    final saved = await showPrinterFormSheet(
      context,
      existing: existing,
      // The first printer a shop registers becomes the default on its own —
      // a one-printer till would otherwise save and see no default anywhere.
      defaultForNew: existing == null && (_printers?.isEmpty ?? true),
      onSave: _store.save,
    );
    await _refresh();
    if (saved != true || !mounted) return;
    showSuccessMessage(context, context.l10n.t('Printer saved'));
  }

  Future<void> _makeDefault(PrinterProfile printer) async {
    await _store.setDefault(printer.id);
    await _refresh();
    if (!mounted) return;
    showSuccessMessage(context, context.l10n.t('Default printer updated.'));
  }

  Future<void> _confirmDelete(PrinterProfile printer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            context.l10n.t('Delete Printer'),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Text(
            context.l10n.t('Delete this printer?'),
            style: TextStyle(color: context.palette.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                context.l10n.t('Cancel'),
                style: TextStyle(color: context.palette.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(context.l10n.t('Delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _store.delete(printer.id);
    await _refresh();
    if (!mounted) return;
    showSuccessMessage(context, context.l10n.t('Printer deleted'));
  }
}
