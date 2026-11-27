import 'package:equatable/equatable.dart';

/// Membership states the backend stores in `users.status`.
///
/// The server normalises a legacy null status to `active`, so the client never
/// has to guess what an absent value means.
enum MemberStatus { pending, active, rejected }

MemberStatus memberStatusFrom(String? raw) {
  return switch (raw?.trim().toLowerCase()) {
    'pending' => MemberStatus.pending,
    'rejected' => MemberStatus.rejected,
    _ => MemberStatus.active,
  };
}

class ShopMember extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final MemberStatus status;
  final bool isVerified;
  final bool activeStatus;
  final DateTime? joinedAt;

  const ShopMember({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.role = '',
    this.status = MemberStatus.active,
    this.isVerified = false,
    this.activeStatus = true,
    this.joinedAt,
  });

  bool get isPending => status == MemberStatus.pending;
  bool get isOwner => role.trim().toLowerCase() == 'owner';
  bool get isManager => role.trim().toLowerCase() == 'manager';

  /// The backend refuses to let a manager edit another manager or the owner.
  /// Mirrored here so the UI does not offer an action that would 403.
  bool isEditableBy(bool actorIsOwner) =>
      actorIsOwner || (!isOwner && !isManager);

  String get roleLabel {
    final normalized = role.trim().toLowerCase();
    if (normalized.isEmpty) return 'Cashier';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    role,
    status,
    isVerified,
    activeStatus,
    joinedAt,
  ];
}

/// The two lists the team screen needs, in the shape the endpoint answers.
class TeamSnapshot extends Equatable {
  final List<ShopMember> pending;
  final List<ShopMember> members;
  final int pendingCount;
  final int activeCount;

  const TeamSnapshot({
    this.pending = const [],
    this.members = const [],
    this.pendingCount = 0,
    this.activeCount = 0,
  });

  @override
  List<Object?> get props => [pending, members, pendingCount, activeCount];
}
