import '../entities/achievement_entity.dart';

abstract interface class AchievementsRepository {
  Future<List<AchievementEntity>> list();
}
