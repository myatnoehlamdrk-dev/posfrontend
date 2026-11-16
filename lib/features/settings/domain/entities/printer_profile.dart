/// A printer the shop has registered in the app's printer settings.
///
/// A profile is an address book entry, not a connection: it records where the
/// printer sits on the network (IP + port) and what roll it prints on, so the
/// operator types the NS06H's IP once instead of per sale, and the receipt
/// layout matches the physical paper. When Wi-Fi is the chosen output, a
/// finished sale sends its ESC/POS bytes straight to this address over raw
/// TCP — the OS print dialog is only the manual fallback.
class PrinterProfile {
  const PrinterProfile({
    required this.id,
    required this.name,
    required this.model,
    required this.host,
    required this.port,
    required this.paperSize,
    this.isDefault = false,
  });

  /// The raw TCP port every ESC/POS-style network printer (NS06H included)
  /// listens on out of the box. Prefilled in the form, still editable for
  /// printers reconfigured to something else.
  static const int defaultPort = 9100;

  /// The paper rolls receipt layout understands. Kept identical to the values
  /// the new-sale print sheet writes so one string drives both surfaces.
  static const String paper58mm = '58mm';
  static const String paper80mm = '80mm';

  /// Stable identifier for updates and deletes. Time-based: printers are
  /// created by one operator on one device, so collisions are not a concern.
  final String id;

  /// What the printer is called on the till — "Counter printer", not a model
  /// number, so the list reads like the counter does.
  final String name;

  /// Hardware model, e.g. `'NS06H'`.
  final String model;

  /// IPv4 address the printer was given on the network, e.g. `'192.168.1.100'`.
  final String host;

  /// TCP port, usually [defaultPort].
  final int port;

  /// `'58mm'` or `'80mm'` — the roll the printer is loaded with.
  final String paperSize;

  /// The printer whose paper size drives the receipt layout.
  final bool isDefault;

  PrinterProfile copyWith({
    String? id,
    String? name,
    String? model,
    String? host,
    int? port,
    String? paperSize,
    bool? isDefault,
  }) {
    return PrinterProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      host: host ?? this.host,
      port: port ?? this.port,
      paperSize: paperSize ?? this.paperSize,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'model': model,
    'host': host,
    'port': port,
    'paperSize': paperSize,
    'isDefault': isDefault,
  };

  /// Tolerant of missing fields: a profile saved by an older build must not
  /// crash the list on read, so every key falls back to a sane value.
  factory PrinterProfile.fromJson(Map<String, dynamic> json) {
    return PrinterProfile(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      model: (json['model'] as String?) ?? 'NS06H',
      host: (json['host'] as String?) ?? '',
      port: (json['port'] as int?) ?? defaultPort,
      paperSize: (json['paperSize'] as String?) ?? paper58mm,
      isDefault: (json['isDefault'] as bool?) ?? false,
    );
  }
}
