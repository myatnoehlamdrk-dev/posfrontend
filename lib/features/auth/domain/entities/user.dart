import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String shopId;
  final String role;
  final String membershipStatus;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.shopId = '',
    this.role = '',
    this.membershipStatus = '',
  });

  @override
  List<Object> get props => [
    id,
    fullName,
    email,
    shopId,
    role,
    membershipStatus,
  ];
}
