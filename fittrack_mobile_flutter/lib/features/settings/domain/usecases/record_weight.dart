import '../repositories/settings_repository.dart';

class RecordWeightUseCase {
  const RecordWeightUseCase(this.repository);
  final SettingsRepository repository;
  Future<void> call(double weight) => repository.recordWeight(weight);
}
