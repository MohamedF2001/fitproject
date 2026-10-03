import '../datasources/exercises_remote_data_source.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/repositories/exercises_repository.dart';

class ExercisesRepositoryImpl implements ExercisesRepository {
  const ExercisesRepositoryImpl(this.remote);
  final ExercisesRemoteDataSource remote;
  @override
  Future<List<ExerciseGroupEntity>> list(
          {String? muscle, String? category}) async =>
      (await remote.list(muscle: muscle, category: category))
          .map((e) => e.toEntity())
          .toList();
  @override
  Future<ExerciseEntity> getById(String id) async =>
      (await remote.getById(id)).toEntity();
}
