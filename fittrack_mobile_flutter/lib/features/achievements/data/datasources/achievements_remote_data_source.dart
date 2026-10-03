import '../../../../core/models/models.dart';
import '../../../../core/network/api_services.dart';

class AchievementsRemoteDataSource {
  const AchievementsRemoteDataSource(this.api);
  final SuccesApiService api;
  Future<List<SuccesModel>> list() => api.list();
}
