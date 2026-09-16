import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String shopId;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.shopId = '',
  });

  @override
  List<Object> get props => [id, fullName, email, shopId];
}
