import '../../../../core/models/models.dart';

class MotivationEntity {
  const MotivationEntity({required this.question, required this.answer});
  final String question, answer;
}

class GoalEntity {
  const GoalEntity(
      {required this.id,
      required this.type,
      this.target,
      this.motivations = const [],
      this.status = 'en_cours',
      this.createdAt,
      this.targetDate});
  final String id, type;
  final double? target;
  final List<MotivationEntity> motivations;
  final String status;
  final DateTime? createdAt, targetDate;
}

extension MotivationMapper on QuestionMotivationModel {
  MotivationEntity toEntity() =>
      MotivationEntity(question: question, answer: reponse);
}

extension GoalMapper on ObjectifModel {
  GoalEntity toEntity() => GoalEntity(
      id: id,
      type: type,
      target: valeurCible,
      motivations: questionsMotivation.map((e) => e.toEntity()).toList(),
      status: statut,
      createdAt: dateCreation,
      targetDate: dateCible);
}

extension GoalEntityMapper on GoalEntity {
  ObjectifInput toInput() => ObjectifInput(
      type: type,
      valeurCible: target,
      dateCible: targetDate,
      reponses: motivations.map((e) => e.answer).toList());
}
