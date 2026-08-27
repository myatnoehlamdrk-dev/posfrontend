import 'package:posfrontend/modules/login/model/login_request.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';

abstract class LoginRepository {
  Future<LoginResponse> login(LoginRequest request);
}
