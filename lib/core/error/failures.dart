import 'package:equatable/equatable.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];

  factory Failure.fromException(AppException e) {
    return switch (e) {
      AuthException() => AuthFailure(e.message),
      NetworkException() => NetworkFailure(e.message),
      TimeoutException() => TimeoutFailure(e.message),
      ValidationException() => ValidationFailure(e.message, fieldErrors: e.fieldErrors),
      ServerException() => ServerFailure(e.message),
      ApiException() => ServerFailure(e.message),
      CancelledException() => CancelledFailure(e.message),
      UnknownException() => ServerFailure(e.message),
    };
  }
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  const ValidationFailure(super.message, {this.fieldErrors});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

class CancelledFailure extends Failure {
  const CancelledFailure(super.message);
}
