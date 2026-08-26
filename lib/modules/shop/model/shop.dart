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
  final String? logoData;
  final String name;
  final String type;
  final String physicalAddress;
  final OwnerInformation ownerInformation;

  const Shop({
    this.logoData,
    required this.name,
    required this.type,
    required this.physicalAddress,
    required this.ownerInformation,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      logoData: json['logoData'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      physicalAddress: json['physicalAddress'] as String,
      ownerInformation:
          OwnerInformation.fromJson(json['ownerInformation'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'logoData': logoData,
        'name': name,
        'type': type,
        'physicalAddress': physicalAddress,
        'ownerInformation': ownerInformation.toJson(),
      };
}
