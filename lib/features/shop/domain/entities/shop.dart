import 'package:equatable/equatable.dart';

class OwnerInformationEntity extends Equatable {
  final String name;
  final String email;
  final String phone;

  const OwnerInformationEntity({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory OwnerInformationEntity.fromJson(Map<String, dynamic> json) {
    return OwnerInformationEntity(
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

  @override
  List<Object?> get props => [name, email, phone];
}

class ShopEntity extends Equatable {
  final String? id;
  final String? logoData;
  final String? logoUrl;
  final String name;
  final String type;
  final String physicalAddress;
  final OwnerInformationEntity ownerInformation;

  const ShopEntity({
    this.id,
    this.logoData,
    this.logoUrl,
    required this.name,
    required this.type,
    required this.physicalAddress,
    required this.ownerInformation,
  });

  factory ShopEntity.fromJson(Map<String, dynamic> json) {
    return ShopEntity(
      id: json['id']?.toString(),
      logoData: json['logoData'] as String?,
      logoUrl: json['logoUrl'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      physicalAddress: json['physicalAddress'] as String,
      ownerInformation:
          OwnerInformationEntity.fromJson(json['ownerInformation'] as Map<String, dynamic>),
    );
  }

  ShopEntity copyWith({
    String? id,
    String? logoData,
    String? logoUrl,
    String? name,
    String? type,
    String? physicalAddress,
    OwnerInformationEntity? ownerInformation,
  }) {
    return ShopEntity(
      id: id ?? this.id,
      logoData: logoData ?? this.logoData,
      logoUrl: logoUrl ?? this.logoUrl,
      name: name ?? this.name,
      type: type ?? this.type,
      physicalAddress: physicalAddress ?? this.physicalAddress,
      ownerInformation: ownerInformation ?? this.ownerInformation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'logoData': logoData,
        'logoUrl': logoUrl,
        'name': name,
        'type': type,
        'physicalAddress': physicalAddress,
        'ownerInformation': ownerInformation.toJson(),
      };

  Map<String, dynamic> toApiJson() => {
        'id': id,
        'logoUrl': logoUrl,
        'name': name,
        'type': type,
        'physicalAddress': physicalAddress,
        'ownerInformation': ownerInformation.toJson(),
      };

  @override
  List<Object?> get props => [id, name, type, physicalAddress, ownerInformation];
}

typedef Shop = ShopEntity;
typedef OwnerInformation = OwnerInformationEntity;
