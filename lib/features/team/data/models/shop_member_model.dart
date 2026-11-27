import 'package:posfrontend/features/team/domain/entities/shop_member.dart';

class ShopMemberModel extends ShopMember {
  const ShopMemberModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.phone,
    super.role,
    super.status,
    super.isVerified,
    super.activeStatus,
    super.joinedAt,
  });

  factory ShopMemberModel.fromJson(Map<String, dynamic> json) {
    return ShopMemberModel(
      id: json['id']?.toString() ?? '',
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
      role: (json['role'] ?? '').toString(),
      status: memberStatusFrom(json['status']?.toString()),
      isVerified: json['isVerified'] == true,
      activeStatus: json['activeStatus'] != false,
      joinedAt: DateTime.tryParse((json['joinedAt'] ?? '').toString()),
    );
  }

  ShopMember toEntity() => ShopMember(
    id: id,
    fullName: fullName,
    email: email,
    phone: phone,
    role: role,
    status: status,
    isVerified: isVerified,
    activeStatus: activeStatus,
    joinedAt: joinedAt,
  );
}

/// Parses `GET shop/members`: pending first, then the rest.
class TeamListModel {
  final List<ShopMemberModel> pending;
  final List<ShopMemberModel> members;
  final int pendingCount;
  final int activeCount;

  const TeamListModel({
    this.pending = const [],
    this.members = const [],
    this.pendingCount = 0,
    this.activeCount = 0,
  });

  factory TeamListModel.fromJson(Map<String, dynamic> json) {
    return TeamListModel(
      pending: _list(json['pending']),
      members: _list(json['members']),
      pendingCount: (json['counts']?['pending'] as num?)?.toInt() ?? 0,
      activeCount: (json['counts']?['active'] as num?)?.toInt() ?? 0,
    );
  }

  static List<ShopMemberModel> _list(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ShopMemberModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  TeamSnapshot toEntity() => TeamSnapshot(
    pending: pending.map((e) => e.toEntity()).toList(),
    members: members.map((e) => e.toEntity()).toList(),
    pendingCount: pendingCount,
    activeCount: activeCount,
  );
}
