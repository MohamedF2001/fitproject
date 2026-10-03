import '../../../../core/models/models.dart';

class AchievementEntity {
  const AchievementEntity(
      {required this.id, required this.description, this.obtainedAt});
  final String id, description;
  final DateTime? obtainedAt;
}

extension AchievementMapper on SuccesModel {
  AchievementEntity toEntity() => AchievementEntity(
      id: id, description: description, obtainedAt: dateObtention);
}
