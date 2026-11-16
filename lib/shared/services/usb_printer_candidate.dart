/// A USB thermal printer the browser (or OS) has granted access to, in the
/// one shape the UI needs — same role as [BluetoothPrinterCandidate].
class UsbPrinterCandidate {
  const UsbPrinterCandidate({
    required this.name,
    required this.vendorId,
    required this.productId,
    this.serial = '',
  });

  /// What the device reports — model number or product string.
  final String name;

  /// USB vendor id, half of the pair used to re-find this device in
  /// [navigator.usb.getDevices] after a page reload.
  final int vendorId;

  /// USB product id — the other half of that pair.
  final int productId;

  /// Device serial when the descriptor has one; optional tie-breaker when a
  /// till has two identical printers plugged in.
  final String serial;
}
