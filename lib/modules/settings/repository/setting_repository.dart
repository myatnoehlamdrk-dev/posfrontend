import 'package:dio/dio.dart';
import 'package:posfrontend/modules/settings/model/settings_models.dart';

abstract class SettingRepository {
  Future<SettingsData> getSettings({CancelToken? cancelToken});
  Future<SettingsData> updateSettings({String? themeMode, String? language, String? shopType, String? shopImage, CancelToken? cancelToken});
}
