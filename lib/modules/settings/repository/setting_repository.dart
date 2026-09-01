import 'package:posfrontend/modules/settings/model/settings_models.dart';

abstract class SettingRepository {
  Future<SettingsData> getSettings();
  Future<SettingsData> updateSettings({String? themeMode, String? language, String? shopType});
}
