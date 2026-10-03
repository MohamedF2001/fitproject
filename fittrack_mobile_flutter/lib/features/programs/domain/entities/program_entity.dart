import '../../../../core/models/models.dart';

class ProgramEntity {
  const ProgramEntity(
      {required this.id,
      required this.name,
      this.days = const [],
      this.active = false,
      this.createdAt});
  final String id, name;
  final List<DayEntity> days;
  final bool active;
  final DateTime? createdAt;
}

class DayEntity {
  const DayEntity(
      {required this.day, this.time = '07:00', this.exercises = const []});
  final String day, time;
  final List<ProgramExerciseEntity> exercises;
}

class ProgramExerciseEntity {
  const ProgramExerciseEntity({required this.exerciseId, required this.order});
  final String exerciseId;
  final int order;
}

extension ProgramMapper on ProgrammeModel {
  ProgramEntity toEntity() => ProgramEntity(
      id: id,
      name: nom,
      days: jours.map((e) => e.toEntity()).toList(),
      active: actif,
      createdAt: dateCreation);
}

extension DayMapper on JourModel {
  DayEntity toEntity() => DayEntity(
      day: jour,
      time: horaire,
      exercises: exercices.map((e) => e.toEntity()).toList());
}

extension ProgramExerciseMapper on ExerciceProgrammeModel {
  ProgramExerciseEntity toEntity() =>
      ProgramExerciseEntity(exerciseId: exerciceId, order: ordre);
}

extension ProgramEntityMapper on ProgramEntity {
  ProgrammeInput toInput() => ProgrammeInput(
      nom: name,
      jours: days
          .map((d) => JourModel(
              jour: d.day,
              horaire: d.time,
              exercices: d.exercises
                  .map((e) => ExerciceProgrammeModel(
                      exerciceId: e.exerciseId, ordre: e.order))
                  .toList()))
          .toList(),
      actif: active);
}
