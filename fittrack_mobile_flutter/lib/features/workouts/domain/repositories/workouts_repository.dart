import '../entities/workout_entity.dart';
import '../../../../core/network/api_services.dart';

abstract interface class WorkoutsRepository {
  Future<WorkoutEntity> create(WorkoutEntity input);
  Future<List<WorkoutEntity>> list();
  Future<WorkoutEntity> getById(String id);
  Future<WorkoutEntity> update(String id, WorkoutEntity input);
  Future<SeanceValidation> validate(String id);
  Future<void> delete(String id);
}
