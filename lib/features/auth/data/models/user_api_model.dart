import 'package:posfrontend/features/auth/domain/entities/user.dart';

class UserApiModel {
  final String id;
  final String fullName;
  final String email;
  final String shopId;

  const UserApiModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.shopId = '',
  });

  factory UserApiModel.fromJson(Map<String, dynamic> json) {
    return UserApiModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      shopId: (json['shopId'] ?? json['shop_id'] ?? '').toString(),
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      fullName: fullName,
      email: email,
      shopId: shopId,
    );
  }
}
