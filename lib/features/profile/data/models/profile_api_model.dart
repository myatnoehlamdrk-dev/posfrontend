import 'package:posfrontend/core/extensions/map_json_extensions.dart';
import 'package:posfrontend/features/profile/domain/entities/profile.dart';

class ProfileApiModel {
  static ProfileEntity fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>?;
    return ProfileEntity(
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

  static Map<String, dynamic> toJson(ProfileEntity profile) {
    return {
      'name': profile.fullName,
      'email': profile.email,
      'type': profile.type,
      'phone': profile.phone,
      'social': profile.social,
      'image': profile.image,
      'image_delete_url': profile.imageDeleteUrl,
      'role': profile.role,
      'address': profile.address,
      'status': profile.status,
      'nrc_no': profile.nrcNo,
      'billing_way': profile.billingWay,
      'date_of_birth': profile.dateOfBirth,
      'gender': profile.gender,
    };
  }
}
