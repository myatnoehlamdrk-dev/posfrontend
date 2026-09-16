import 'package:posfrontend/features/auth/domain/entities/user.dart';

class LoginResponseModel {
  final String id;
  final String fullName;
  final String email;
  final String accessToken;
  final String tokenType;
  final String shopId;

  const LoginResponseModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.accessToken,
    required this.tokenType,
    this.shopId = '',
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
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
