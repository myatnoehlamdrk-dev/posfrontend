class LoginResponse {
  final String id;
  final String fullName;
  final String email;
  final String accessToken;
  final String tokenType;
  final String shopId;
  final String role;
  final String membershipStatus;

  const LoginResponse({
    required this.id,
    required this.fullName,
    required this.email,
    required this.accessToken,
    required this.tokenType,
    this.shopId = '',
    this.role = '',
    this.membershipStatus = 'active',
  });

  bool get isOwner => role.toLowerCase().trim() == 'owner';

  /// Owner or manager: the two roles that may review join requests.
  bool get canManageTeam {
    final normalized = role.toLowerCase().trim();
    return normalized == 'owner' || normalized == 'manager';
  }

  bool get isActiveMember =>
      membershipStatus.isEmpty ||
      membershipStatus.toLowerCase().trim() == 'active';

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      shopId: (json['shopId'] ?? json['shop_id'] ?? '').toString(),
      role: json['role'] as String? ?? '',
      membershipStatus:
          (json['membershipStatus'] ?? json['status'] ?? 'active').toString(),
    );
  }
}
