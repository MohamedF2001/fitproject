import '../../../../core/models/models.dart';

class ExerciseEntity {
  const ExerciseEntity(
      {required this.id,
      required this.nameFr,
      this.uuid = '',
      this.descriptionFr = '',
      this.category = '',
      this.musclesPrimary = const [],
      this.musclesSecondary = const [],
      this.equipment = '',
      this.muscle});
  final String id, uuid, nameFr, descriptionFr, category, equipment;
  final List<String> musclesPrimary, musclesSecondary;
  final String? muscle;
}

class ExerciseGroupEntity {
  const ExerciseGroupEntity({required this.muscle, required this.exercises});
  final String muscle;
  final List<ExerciseEntity> exercises;
}

extension ExerciseModelMapper on ExerciceModel {
  ExerciseEntity toEntity() => ExerciseEntity(
      id: id,
      uuid: uuid,
      nameFr: nameFr,
      descriptionFr: descriptionFr,
      category: category,
      musclesPrimary: musclesPrimary,
      musclesSecondary: musclesSecondary,
      equipment: equipment,
      muscle: muscle);
}

extension ExerciseGroupMapper on GroupeExerciceModel {
  ExerciseGroupEntity toEntity() => ExerciseGroupEntity(
      muscle: muscle, exercises: exercices.map((e) => e.toEntity()).toList());
}
