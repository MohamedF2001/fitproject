import '../../../../core/models/models.dart';

class UserEntity {
  const UserEntity(
      {required this.id,
      required this.email,
      this.nom,
      this.prenom,
      this.poids,
      this.taille});
  final String id;
  final String email;
  final String? nom;
  final String? prenom;
  final double? poids;
  final double? taille;
  bool get isComplete =>
      nom?.trim().isNotEmpty == true &&
      prenom?.trim().isNotEmpty == true &&
      poids != null &&
      taille != null;
}

extension UserModelMapper on UserModel {
  UserEntity toEntity() => UserEntity(
      id: id,
      email: email,
      nom: nom,
      prenom: prenom,
      poids: poids,
      taille: taille);
}

extension UserEntityMapper on UserEntity {
  UserModel toModel() => UserModel(
      id: id,
      email: email,
      nom: nom,
      prenom: prenom,
      poids: poids,
      taille: taille);
}
