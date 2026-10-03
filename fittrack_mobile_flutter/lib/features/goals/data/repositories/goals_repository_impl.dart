import '../../domain/entities/goal_entity.dart';
import '../../domain/repositories/goals_repository.dart';
import '../datasources/goals_remote_data_source.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  const GoalsRepositoryImpl(this.remote);
  final GoalsRemoteDataSource remote;
  @override
  Future<GoalEntity> create(GoalEntity x) async =>
      (await remote.create(x.toInput())).toEntity();
  @override
  Future<List<GoalEntity>> list() async =>
      (await remote.list()).map((e) => e.toEntity()).toList();
  @override
  Future<GoalEntity> getById(String id) async =>
      (await remote.getById(id)).toEntity();
  @override
  Future<GoalEntity> update(String id, GoalEntity x) async =>
      (await remote.update(id, x.toInput())).toEntity();
}
