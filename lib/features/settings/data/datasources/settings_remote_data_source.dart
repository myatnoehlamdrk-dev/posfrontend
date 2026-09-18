import 'package:dio/dio.dart';

abstract class SettingsRemoteDataSource {
  Future<Response> getSettings({CancelToken? cancelToken});
  Future<Response> updateSettings({String? themeMode, String? language, String? shopType, String? shopImage, CancelToken? cancelToken});
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final Dio dio;

  SettingsRemoteDataSourceImpl(this.dio);

  @override
  Future<Response> getSettings({CancelToken? cancelToken}) {
    return dio.get('/api/settings', cancelToken: cancelToken);
  }

  @override
  Future<Response> updateSettings({String? themeMode, String? language, String? shopType, String? shopImage, CancelToken? cancelToken}) {
    final body = <String, dynamic>{};
    if (themeMode != null) body['theme_mode'] = themeMode;
    if (language != null) body['language'] = language;
    if (shopType != null) body['shop_type'] = shopType;
    if (shopImage != null) body['shop_image'] = shopImage;
    return dio.patch('/api/settings', data: body, cancelToken: cancelToken);
  }
}
