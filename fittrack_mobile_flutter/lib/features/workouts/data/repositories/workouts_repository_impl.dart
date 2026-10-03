import '../../domain/entities/workout_entity.dart';
import '../../domain/repositories/workouts_repository.dart';
import '../datasources/workouts_remote_data_source.dart';
import '../../../../core/network/api_services.dart';

class WorkoutsRepositoryImpl implements WorkoutsRepository {
  const WorkoutsRepositoryImpl(this.remote);
  final WorkoutsRemoteDataSource remote;
  @override
  Future<WorkoutEntity> create(WorkoutEntity x) async =>
      (await remote.create(x.toInput())).toEntity();
  @override
  Future<List<WorkoutEntity>> list() async =>
      (await remote.list()).map((e) => e.toEntity()).toList();
  @override
  Future<WorkoutEntity> getById(String id) async =>
      (await remote.getById(id)).toEntity();
  @override
  Future<WorkoutEntity> update(String id, WorkoutEntity x) async =>
      (await remote.update(id, x.toInput())).toEntity();
  @override
  Future<SeanceValidation> validate(String id) => remote.validate(id);
  @override
  Future<void> delete(String id) => remote.delete(id);
}
