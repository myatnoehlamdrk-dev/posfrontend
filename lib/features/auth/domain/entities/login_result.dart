import 'package:equatable/equatable.dart';
import 'package:posfrontend/features/auth/domain/entities/user.dart';

class LoginResult extends Equatable {
  final UserEntity user;
  final String accessToken;

  const LoginResult({required this.user, required this.accessToken});

  @override
  List<Object> get props => [user, accessToken];
}
