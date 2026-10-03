import '../entities/goal_entity.dart';

abstract interface class GoalsRepository {
  Future<GoalEntity> create(GoalEntity input);
  Future<List<GoalEntity>> list();
  Future<GoalEntity> getById(String id);
  Future<GoalEntity> update(String id, GoalEntity input);
}
