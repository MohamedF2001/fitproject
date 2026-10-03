import '../entities/settings_entity.dart';

abstract interface class SettingsRepository {
  SettingsEntity get settings;
  Future<void> recordWeight(double weight);
}
