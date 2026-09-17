import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/settings/domain/entities/settings.dart';
import 'package:posfrontend/features/settings/domain/repositories/settings_repository.dart';

class GetSettingsUseCase extends UseCase<SettingsEntity, NoParams> {
  final SettingsRepository repository;

  GetSettingsUseCase(this.repository);

  @override
  Future<SettingsEntity> call(NoParams params) {
    return repository.getSettings();
  }
}

class UpdateSettingsUseCase extends UseCase<SettingsEntity, UpdateSettingsParams> {
  final SettingsRepository repository;

  UpdateSettingsUseCase(this.repository);

  @override
  Future<SettingsEntity> call(UpdateSettingsParams params) {
    return repository.updateSettings(
      themeMode: params.themeMode,
      language: params.language,
      shopType: params.shopType,
      shopImage: params.shopImage,
    );
  }
}

class UpdateSettingsParams {
  final String? themeMode;
  final String? language;
  final String? shopType;
  final String? shopImage;

  UpdateSettingsParams({this.themeMode, this.language, this.shopType, this.shopImage});
}
