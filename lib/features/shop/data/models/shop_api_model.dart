import 'package:posfrontend/features/shop/domain/entities/shop.dart';

class ShopApiModel {
  final String? id;
  final String? logoUrl;
  final String? logoData;
  final String? name;
  final String? type;
  final String? physicalAddress;
  final OwnerInformationModel ownerInformation;

  const ShopApiModel({
    this.id,
    this.logoUrl,
    this.logoData,
    this.name,
    this.type,
    this.physicalAddress,
    required this.ownerInformation,
  });

  factory ShopApiModel.fromJson(Map<String, dynamic> json) {
    return ShopApiModel(
      id: json['id']?.toString(),
      logoData: json['logoData'] as String?,
      logoUrl: json['logoUrl'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      physicalAddress: json['physicalAddress'] as String?,
      ownerInformation: OwnerInformationModel.fromJson(
        json['ownerInformation'] as Map<String, dynamic>,
      ),
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

  ShopEntity toEntity() {
    return ShopEntity(
      id: id,
      logoUrl: logoUrl,
      name: name ?? '',
      type: type ?? '',
      physicalAddress: physicalAddress ?? '',
      ownerInformation: OwnerInformationEntity(
        name: ownerInformation.name,
        email: ownerInformation.email,
        phone: ownerInformation.phone,
      ),
    );
  }

  factory ShopApiModel.fromEntity(ShopEntity entity) {
    return ShopApiModel(
      id: entity.id,
      logoUrl: entity.logoUrl,
      name: entity.name,
      type: entity.type,
      physicalAddress: entity.physicalAddress,
      ownerInformation: OwnerInformationModel(
        name: entity.ownerInformation.name,
        email: entity.ownerInformation.email,
        phone: entity.ownerInformation.phone,
      ),
    );
  }
}

class OwnerInformationModel {
  final String name;
  final String email;
  final String phone;

  const OwnerInformationModel({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory OwnerInformationModel.fromJson(Map<String, dynamic> json) {
    return OwnerInformationModel(
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
