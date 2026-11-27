import 'package:posfrontend/features/auth/domain/entities/user.dart';

class UserApiModel {
  final String id;
  final String fullName;
  final String email;
  final String shopId;
  final String role;

  /// Normalised membership state returned by registration. The raw `status`
  /// column is kept as a fallback for older servers that do not send it.
  final String membershipStatus;

  const UserApiModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.shopId = '',
    this.role = '',
    this.membershipStatus = 'active',
  });

  factory UserApiModel.fromJson(Map<String, dynamic> json) {
    return UserApiModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      shopId: (json['shopId'] ?? json['shop_id'] ?? '').toString(),
      role: json['role'] as String? ?? '',
      membershipStatus:
          (json['membershipStatus'] ?? json['status'] ?? 'active').toString(),
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      fullName: fullName,
      email: email,
      shopId: shopId,
      role: role,
      membershipStatus: membershipStatus,
    );
  }
}
