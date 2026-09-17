import 'package:dio/dio.dart';

abstract class ProfileRemoteDataSource {
  Future<Response> getProfile({CancelToken? cancelToken});
  Future<Response> updateProfile(Map<String, dynamic> data, {CancelToken? cancelToken});
  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    CancelToken? cancelToken,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSourceImpl(this.dio);

  @override
  Future<Response> getProfile({CancelToken? cancelToken}) {
    return dio.get('/api/auth/profile', cancelToken: cancelToken);
  }

  @override
  Future<Response> updateProfile(Map<String, dynamic> data, {CancelToken? cancelToken}) {
    return dio.put('/api/auth/profile', data: data, cancelToken: cancelToken);
  }

  @override
  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    CancelToken? cancelToken,
  }) {
    return dio.put('/api/auth/profile/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    }, cancelToken: cancelToken);
  }
}
