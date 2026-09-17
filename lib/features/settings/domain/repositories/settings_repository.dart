import 'package:posfrontend/features/settings/domain/entities/settings.dart';

abstract class SettingsRepository {
  Future<SettingsEntity> getSettings();
  Future<SettingsEntity> updateSettings({String? themeMode, String? language, String? shopType, String? shopImage});
}
