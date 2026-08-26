import 'package:posfrontend/modules/register/model/register_request.dart';
import 'package:posfrontend/modules/register/model/user_model.dart';

abstract class AuthRepository {
  Future<User> register(RegisterRequest request);
}
