import '../repositories/exercises_repository.dart';
import '../entities/exercise_entity.dart';

class ListExercisesUseCase {
  const ListExercisesUseCase(this.repository);
  final ExercisesRepository repository;
  Future<List<ExerciseGroupEntity>> call({String? muscle, String? category}) =>
      repository.list(muscle: muscle, category: category);
}
