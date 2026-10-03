import '../repositories/achievements_repository.dart';
import '../entities/achievement_entity.dart';

class ListAchievementsUseCase {
  const ListAchievementsUseCase(this.repository);
  final AchievementsRepository repository;
  Future<List<AchievementEntity>> call() => repository.list();
}
