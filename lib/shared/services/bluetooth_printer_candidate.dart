/// A Bluetooth printer the OS knows about, in the one shape the UI needs.
///
/// The plugin's own type (`BluetoothInfo`) lives behind the platform split,
/// so the picker sheet never imports it.
class BluetoothPrinterCandidate {
  const BluetoothPrinterCandidate({required this.name, required this.address});

  /// What the OS calls it — usually the model number or whatever the
  /// operator nicknamed it while pairing.
  final String name;

  /// A MAC address on Android, a Core Bluetooth UUID string on iOS.
  final String address;
}
