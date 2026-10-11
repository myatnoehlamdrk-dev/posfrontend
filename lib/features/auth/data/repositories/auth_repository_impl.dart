import 'package:posfrontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:posfrontend/features/auth/data/models/login_request_model.dart';
import 'package:posfrontend/features/auth/data/models/register_request_model.dart';
import 'package:posfrontend/features/auth/domain/entities/login_result.dart';
import 'package:posfrontend/features/auth/domain/entities/user.dart';
import 'package:posfrontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({AuthRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource();

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequestModel(
        email: email,
        password: password,
        deviceName: deviceName,
      ),
    );
    return LoginResult(
      user: response.toEntity(),
      accessToken: response.accessToken,
    );
  }

  @override
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? social,
    String? role,
    String? address,
    String? nrc,
    String? billingWay,
    String? dob,
    String? gender,
    String? shopId,
    ShopEntity? shop,
  }) async {
    final response = await _remoteDataSource.register(
      RegisterRequestModel(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        social: social,
        role: role,
        address: address,
        nrc: nrc,
        billingWay: billingWay,
        dob: dob,
        gender: gender,
        shopId: shopId,
        shop: shop == null ? null : _shopPayload(shop),
      ),
    );
    return response.toEntity();
  }

  /// The registration shape for a shop that does not exist server-side yet.
  ///
  /// Deliberately without `id`: the server assigns it, and echoing the local
  /// one (always absent here) would invite the backend to trust a client-made
  /// identifier. [logoData] rides along as raw base64 because the authenticated
  /// upload endpoint cannot be called before this account exists.
  Map<String, dynamic> _shopPayload(ShopEntity shop) => {
    'name': shop.name,
    'type': shop.type,
    'physicalAddress': shop.physicalAddress,
    'logoUrl': shop.logoUrl,
    'logoData': shop.logoData,
    'ownerInformation': shop.ownerInformation.toJson(),
  };

  @override
  Future<void> sendOtp({required String email}) {
    return _remoteDataSource.sendOtp(email);
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) {
    return _remoteDataSource.verifyOtp(email, otp);
  }

  @override
  Future<void> sendForgotPasswordOtp({required String email}) {
    return _remoteDataSource.sendForgotPasswordOtp(email);
  }

  @override
  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) {
    return _remoteDataSource.verifyForgotPasswordOtp(email, otp);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
  }) {
    return _remoteDataSource.resetPassword(
      email: email,
      resetToken: resetToken,
      password: password,
    );
  }
}
