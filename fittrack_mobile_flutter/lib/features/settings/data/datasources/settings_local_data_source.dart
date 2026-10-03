import '../../../../core/storage/local_storage.dart';

class SettingsLocalDataSource {
  const SettingsLocalDataSource(this.storage);
  final LocalStorage storage;
  List<Map<String, dynamic>> get weightHistory => storage.weightHistory;
  Future<void> addWeight(double weight) => storage.addWeight(weight);
}
