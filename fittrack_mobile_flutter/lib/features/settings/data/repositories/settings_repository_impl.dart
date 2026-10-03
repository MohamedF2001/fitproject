import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this.local);
  final SettingsLocalDataSource local;
  @override
  SettingsEntity get settings => const SettingsEntity();
  @override
  Future<void> recordWeight(double weight) => local.addWeight(weight);
}
