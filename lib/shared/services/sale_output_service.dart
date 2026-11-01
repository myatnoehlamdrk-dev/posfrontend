import 'package:posfrontend/features/settings/data/printer_profile_store.dart';
import 'package:posfrontend/features/settings/domain/entities/printer_profile.dart';
import 'package:posfrontend/shared/services/print_output_exception.dart';
import 'package:posfrontend/shared/services/receipt_print_service.dart';
import 'package:posfrontend/shared/services/thermal_receipt_builder.dart';
import 'package:posfrontend/shared/services/thermal_printer_transport.dart';
import 'package:posfrontend/shared/services/usb_printer_transport.dart';

/// Decides what happens to a finished sale's voucher — the single route both
/// sale surfaces call, so one setting really does drive both.
///
/// Direct thermal failures throw [PrintOutputException] with a message meant
/// for the operator; the callers turn that into a snackbar that offers the OS
/// print dialog as the manual way out. The sale itself is already stored when
/// this runs, so nothing here can undo it.
abstract final class SaleOutputService {
  /// Runs the chosen output for [args] (built by [ReceiptPrintService]).
  static Future<void> printAfterSale(
    Map<String, dynamic> args,
    SalePrintSettings settings,
  ) async {
    switch (settings.output) {
      case SalePrintSettings.outputBluetooth:
        if (!ThermalPrinterTransport.isSupported) {
          throw const PrintOutputException(
            'Bluetooth printing is not available in the browser.',
          );
        }
        if (settings.btPrinterAddress.isEmpty) {
          throw const PrintOutputException(
            'No Bluetooth printer selected. Choose one in Print Settings.',
          );
        }
        final bluetoothJob = await ThermalReceiptBuilder.build(
          args,
          paperSize: settings.paperSize,
        );
        await ThermalPrinterTransport.sendToBluetooth(
          address: settings.btPrinterAddress,
          bytes: bluetoothJob,
        );

      case SalePrintSettings.outputWifi:
        if (!ThermalPrinterTransport.isSupported) {
          throw const PrintOutputException(
            'Wi-Fi printing is not available in the browser.',
          );
        }
        final printer = await defaultNetworkPrinter();
        if (printer == null) {
          throw const PrintOutputException(
            'No printer configured. Add one in Settings > Printers.',
          );
        }
        // The sheet's paper size, not the profile's: the profile seeds it
        // when the default printer changes, but an operator who narrows it
        // in Print Settings means that. One key drives both surfaces.
        final wifiJob = await ThermalReceiptBuilder.build(
          args,
          paperSize: settings.paperSize,
        );
        await ThermalPrinterTransport.sendToWifi(
          host: printer.host,
          port: printer.port,
          bytes: wifiJob,
        );

      case SalePrintSettings.outputUsb:
        if (!UsbPrinterTransport.isSupported) {
          throw const PrintOutputException(
            'USB printing is not available on this device.',
          );
        }
        final usbJob = await ThermalReceiptBuilder.build(
          args,
          paperSize: settings.paperSize,
        );
        await UsbPrinterTransport.send(bytes: usbJob);

      default:
        await ReceiptPrintService.exportPdf(args);
    }
  }

  /// The network printer thermal Wi-Fi prints go to: the default profile,
  /// falling back to the first saved one (the store sorts the default first,
  /// so these are the same unless nothing is marked default). Null means the
  /// operator has never set a printer up.
  static Future<PrinterProfile?> defaultNetworkPrinter() async {
    final printers = await PrinterProfileStore().load();
    return printers.isEmpty ? null : printers.first;
  }
}
