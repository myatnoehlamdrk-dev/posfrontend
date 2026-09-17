import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/settings/domain/entities/settings.dart';
import 'package:posfrontend/features/settings/domain/repositories/settings_repository.dart';
import 'package:posfrontend/features/settings/data/models/settings_api_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final dio = ApiClient.create();

  @override
  Future<SettingsEntity> getSettings() async {
    final response = await dio.get('/api/settings');
    return SettingsApiModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SettingsEntity> updateSettings({String? themeMode, String? language, String? shopType, String? shopImage}) async {
    final body = <String, dynamic>{};
    if (themeMode != null) body['theme_mode'] = themeMode;
    if (language != null) body['language'] = language;
    if (shopType != null) body['shop_type'] = shopType;
    if (shopImage != null) body['shop_image'] = shopImage;

    final response = await dio.put('/api/settings', data: body);
    return SettingsApiModel.fromJson(response.data as Map<String, dynamic>);
  }
}
