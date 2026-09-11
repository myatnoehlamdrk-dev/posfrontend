import 'package:posfrontend/core/extensions/map_json_extensions.dart';

class ProfileResponse {
  final String id;
  final String fullName;
  final String email;
  final String type;
  final String phone;
  final String social;
  final String image;
  final String imageDeleteUrl;
  final String role;
  final String address;
  final String status;
  final String nrcNo;
  final String billingWay;
  final String dateOfBirth;
  final String gender;
  final bool activeStatus;
  final String shopId;
  final String shopName;

  const ProfileResponse({
    required this.id,
    required this.fullName,
    required this.email,
    this.type = '',
    this.phone = '',
    this.social = '',
    this.image = '',
    this.imageDeleteUrl = '',
    this.role = '',
    this.address = '',
    this.status = '',
    this.nrcNo = '',
    this.billingWay = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.activeStatus = true,
    this.shopId = '',
    this.shopName = '',
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>?;
    return ProfileResponse(
      id: json['id']?.toString() ?? '',
      fullName: json.str('fullName'),
      email: json.str('email'),
      type: json.str('type'),
      phone: json.str('phone'),
      social: json.str('social'),
      image: json.str('image'),
      imageDeleteUrl: json.str('imageDeleteUrl'),
      role: json.str('role'),
      address: json.str('address'),
      status: json.str('status'),
      nrcNo: json.str('nrcNo'),
      billingWay: json.str('billingWay'),
      dateOfBirth: json.str('dateOfBirth'),
      gender: json.str('gender'),
      activeStatus: json['activeStatus'] as bool? ?? true,
      shopId: json['shopId']?.toString() ?? '',
      shopName: shop?['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': fullName,
      'email': email,
      'type': type,
      'phone': phone,
      'social': social,
      'image': image,
      'image_delete_url': imageDeleteUrl,
      'role': role,
      'address': address,
      'status': status,
      'nrc_no': nrcNo,
      'billing_way': billingWay,
      'date_of_birth': dateOfBirth,
      'gender': gender,
    };
  }
}
