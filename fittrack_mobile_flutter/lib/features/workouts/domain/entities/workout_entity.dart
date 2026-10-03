import '../../../../core/models/models.dart';

class SetEntity {
  const SetEntity(
      {required this.number, required this.repetitions, required this.load});
  final int number, repetitions;
  final double load;
}

class WorkoutExerciseEntity {
  const WorkoutExerciseEntity(
      {required this.exerciseId, this.sets = const [], this.restSeconds = 60});
  final String exerciseId;
  final List<SetEntity> sets;
  final int restSeconds;
}

class WorkoutEntity {
  const WorkoutEntity(
      {required this.id,
      this.date,
      this.exercises = const [],
      this.status = 'brouillon',
      this.validatedAt});
  final String id;
  final DateTime? date;
  final List<WorkoutExerciseEntity> exercises;
  final String status;
  final DateTime? validatedAt;
}

extension SetMapper on SerieModel {
  SetEntity toEntity() =>
      SetEntity(number: numero, repetitions: repetitions, load: charge);
}

extension WorkoutExerciseMapper on ExerciceSeanceModel {
  WorkoutExerciseEntity toEntity() => WorkoutExerciseEntity(
      exerciseId: exerciceId,
      sets: series.map((e) => e.toEntity()).toList(),
      restSeconds: tempsRepos);
}

extension WorkoutMapper on SeanceModel {
  WorkoutEntity toEntity() => WorkoutEntity(
      id: id,
      date: date,
      exercises: exercices.map((e) => e.toEntity()).toList(),
      status: statut,
      validatedAt: valideeLe);
}

extension WorkoutEntityMapper on WorkoutEntity {
  SeanceInput toInput() => SeanceInput(
      date: date,
      exercices: exercises
          .map((e) => ExerciceSeanceModel(
              exerciceId: e.exerciseId,
              tempsRepos: e.restSeconds,
              series: e.sets
                  .map((s) => SerieModel(
                      numero: s.number,
                      repetitions: s.repetitions,
                      charge: s.load))
                  .toList()))
          .toList());
}
