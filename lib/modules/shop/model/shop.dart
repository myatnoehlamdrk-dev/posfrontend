class OwnerInformation {
  final String name;
  final String email;
  final String phone;

  const OwnerInformation({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory OwnerInformation.fromJson(Map<String, dynamic> json) {
    return OwnerInformation(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
      };
}

class Shop {
  final String? id;
  final String? logoData;
  final String? logoUrl;
  final String name;
  final String type;
  final String physicalAddress;
  final OwnerInformation ownerInformation;

  const Shop({
    this.id,
    this.logoData,
    this.logoUrl,
    required this.name,
    required this.type,
    required this.physicalAddress,
    required this.ownerInformation,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id']?.toString(),
      logoData: json['logoData'] as String?,
      logoUrl: json['logoUrl'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      physicalAddress: json['physicalAddress'] as String,
      ownerInformation:
          OwnerInformation.fromJson(json['ownerInformation'] as Map<String, dynamic>),
    );
  }

  Shop copyWith({
    String? id,
    String? logoData,
    String? logoUrl,
    String? name,
    String? type,
    String? physicalAddress,
    OwnerInformation? ownerInformation,
  }) {
    return Shop(
      id: id ?? this.id,
      logoData: logoData ?? this.logoData,
      logoUrl: logoUrl ?? this.logoUrl,
      name: name ?? this.name,
      type: type ?? this.type,
      physicalAddress: physicalAddress ?? this.physicalAddress,
      ownerInformation: ownerInformation ?? this.ownerInformation,
    );
  }

  /// Local persistence payload (keeps the interim base64 image).
  Map<String, dynamic> toJson() => {
        'id': id,
        'logoData': logoData,
        'logoUrl': logoUrl,
        'name': name,
        'type': type,
        'physicalAddress': physicalAddress,
        'ownerInformation': ownerInformation.toJson(),
      };

  /// Backend payload — sends the hosted URL only (no base64).
  Map<String, dynamic> toApiJson() => {
        'id': id,
        'logoUrl': logoUrl,
        'name': name,
        'type': type,
        'physicalAddress': physicalAddress,
        'ownerInformation': ownerInformation.toJson(),
      };
}
