import '../../domain/entities/achievement_entity.dart';
import '../../domain/repositories/achievements_repository.dart';
import '../datasources/achievements_remote_data_source.dart';

class AchievementsRepositoryImpl implements AchievementsRepository {
  const AchievementsRepositoryImpl(this.remote);
  final AchievementsRemoteDataSource remote;
  @override
  Future<List<AchievementEntity>> list() async =>
      (await remote.list()).map((e) => e.toEntity()).toList();
}
