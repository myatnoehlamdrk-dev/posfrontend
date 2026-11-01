import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/services/bluetooth_printer_candidate.dart';
import 'package:posfrontend/shared/services/thermal_printer_transport.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// The Bluetooth half of Print Settings: printers the OS already knows,
/// offered as pick-and-dismiss.
///
/// On Android this is the *paired* list — pairing itself happens in system
/// settings, so an empty result means "go pair it", not a bug — while iOS
/// scans nearby for a few seconds instead. Popping returns the chosen
/// candidate; dismissing unchanged pops null.
class BluetoothPrinterPicker extends StatefulWidget {
  const BluetoothPrinterPicker({super.key, this.selectedAddress = ''});

  /// Shown with a check so the operator can see what is already selected.
  final String selectedAddress;

  @override
  State<BluetoothPrinterPicker> createState() => _BluetoothPrinterPickerState();
}

class _BluetoothPrinterPickerState extends State<BluetoothPrinterPicker> {
  late Future<List<BluetoothPrinterCandidate>> _future;

  AppPalette get _p => context.palette;

  @override
  void initState() {
    super.initState();
    _future = ThermalPrinterTransport.listPaired();
  }

  void _reload() =>
      setState(() => _future = ThermalPrinterTransport.listPaired());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _p.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.t('Choose Bluetooth Printer'),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _p.textPrimary,
                ),
              ),
              IconButton(
                onPressed: _reload,
                tooltip: context.l10n.t('Refresh'),
                icon: Icon(Icons.refresh, color: _p.textSecondary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: FutureBuilder<List<BluetoothPrinterCandidate>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _status(
                    icon: Icons.error_outline,
                    title: context.l10n.t('${snapshot.error}'),
                    actionLabel: context.l10n.t('Retry'),
                    onAction: _reload,
                  );
                }
                final printers = snapshot.data ?? const [];
                if (printers.isEmpty) {
                  return _status(
                    icon: Icons.bluetooth_searching,
                    title: context.l10n.t('No printers found'),
                    detail: context.l10n.t(
                      'Pair the printer in system settings, then refresh.',
                    ),
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final printer in printers)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.print_outlined,
                          color: _p.textSecondary,
                          size: 22,
                        ),
                        title: Text(
                          printer.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _p.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          printer.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: _p.textSecondary,
                          ),
                        ),
                        trailing: printer.address == widget.selectedAddress
                            ? Icon(
                                Icons.check_circle,
                                color: _p.accentText,
                                size: 20,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, printer),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _status({
    required IconData icon,
    required String title,
    String? detail,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: _p.textMuted, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _p.textSecondary),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _p.textMuted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: _p.accentText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
