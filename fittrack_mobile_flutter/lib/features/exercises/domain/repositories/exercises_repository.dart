import '../entities/exercise_entity.dart';

abstract interface class ExercisesRepository {
  Future<List<ExerciseGroupEntity>> list({String? muscle, String? category});
  Future<ExerciseEntity> getById(String id);
}
