import 'package:json_annotation/json_annotation.dart';

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
String _string(dynamic value) => value?.toString() ?? '';
Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

@JsonSerializable()
class UserModel {
  const UserModel({
    this.id = '',
    required this.email,
    this.nom,
    this.prenom,
    this.poids,
    this.taille,
    this.createdAt,
    this.updatedAt,
  });
  final String id;
  final String email;
  final String? nom;
  final String? prenom;
  final double? poids;
  final double? taille;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: _string(json['_id'] ?? json['id']),
        email: _string(json['email']),
        nom: json['nom']?.toString(),
        prenom: json['prenom']?.toString(),
        poids: (json['poids'] as num?)?.toDouble(),
        taille: (json['taille'] as num?)?.toDouble(),
        createdAt: _date(json['createdAt']),
        updatedAt: _date(json['updatedAt']),
      );
  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'email': email,
        if (nom != null) 'nom': nom,
        if (prenom != null) 'prenom': prenom,
        if (poids != null) 'poids': poids,
        if (taille != null) 'taille': taille,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
  bool get isComplete =>
      nom?.trim().isNotEmpty == true &&
      prenom?.trim().isNotEmpty == true &&
      poids != null &&
      taille != null;
}

class AuthResponseModel {
  const AuthResponseModel({
    required this.message,
    required this.token,
    required this.user,
  });
  final String message;
  final String token;
  final UserModel user;
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      AuthResponseModel(
        message: _string(json['message']),
        token: _string(json['token']),
        user: UserModel.fromJson(_map(json['user'])),
      );
  Map<String, dynamic> toJson() => {
        'message': message,
        'token': token,
        'user': user.toJson(),
      };
}

class ExerciceModel {
  const ExerciceModel({
    required this.id,
    this.uuid = '',
    this.nameFr = '',
    this.descriptionFr = '',
    this.category = '',
    this.musclesPrimary = const [],
    this.musclesSecondary = const [],
    this.equipment = '',
    this.muscle,
  });
  final String id;
  final String uuid;
  final String nameFr;
  final String descriptionFr;
  final String category;
  final List<String> musclesPrimary;
  final List<String> musclesSecondary;
  final String equipment;
  final String? muscle;
  factory ExerciceModel.fromJson(Map<String, dynamic> json) => ExerciceModel(
        id: _string(json['id'] ?? json['_id']),
        uuid: _string(json['uuid']),
        nameFr: _string(json['name_fr']),
        descriptionFr: _string(json['description_fr']),
        category: _string(json['category']),
        musclesPrimary: List<String>.from(
          json['muscles_primary'] ?? const <String>[],
        ),
        musclesSecondary: List<String>.from(
          json['muscles_secondary'] ?? const <String>[],
        ),
        equipment: _string(json['equipment']),
        muscle: json['muscle']?.toString(),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'name_fr': nameFr,
        'description_fr': descriptionFr,
        'category': category,
        'muscles_primary': musclesPrimary,
        'muscles_secondary': musclesSecondary,
        'equipment': equipment,
        if (muscle != null) 'muscle': muscle,
      };
}

class GroupeExerciceModel {
  const GroupeExerciceModel({required this.muscle, required this.exercices});
  final String muscle;
  final List<ExerciceModel> exercices;
  factory GroupeExerciceModel.fromJson(Map<String, dynamic> json) =>
      GroupeExerciceModel(
        muscle: _string(json['muscle']),
        exercices: (json['exercices'] as List? ?? const [])
            .map((e) => ExerciceModel.fromJson(_map(e)))
            .toList(),
      );
  Map<String, dynamic> toJson() => {
        'muscle': muscle,
        'exercices': exercices.map((e) => e.toJson()).toList(),
      };
}

class ExerciceProgrammeModel {
  const ExerciceProgrammeModel({required this.exerciceId, required this.ordre});
  final String exerciceId;
  final int ordre;
  factory ExerciceProgrammeModel.fromJson(Map<String, dynamic> json) =>
      ExerciceProgrammeModel(
        exerciceId: _string(json['exerciceId']),
        ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      );
  Map<String, dynamic> toJson() => {'exerciceId': exerciceId, 'ordre': ordre};
}

class JourModel {
  const JourModel({
    required this.jour,
    this.horaire = '07:00',
    this.exercices = const [],
  });
  final String jour;
  final String horaire;
  final List<ExerciceProgrammeModel> exercices;
  factory JourModel.fromJson(Map<String, dynamic> json) => JourModel(
        jour: _string(json['jour']),
        horaire: _string(json['horaire']).isEmpty
            ? '07:00'
            : _string(json['horaire']),
        exercices: (json['exercices'] as List? ?? const [])
            .map((e) => ExerciceProgrammeModel.fromJson(_map(e)))
            .toList(),
      );
  Map<String, dynamic> toJson() => {
        'jour': jour,
        'horaire': horaire,
        'exercices': exercices.map((e) => e.toJson()).toList(),
      };
}

class ProgrammeModel {
  const ProgrammeModel({
    required this.id,
    required this.nom,
    this.jours = const [],
    this.actif = false,
    this.dateCreation,
    this.utilisateur,
  });
  final String id;
  final String nom;
  final List<JourModel> jours;
  final bool actif;
  final DateTime? dateCreation;
  final UserModel? utilisateur;
  factory ProgrammeModel.fromJson(Map<String, dynamic> json) => ProgrammeModel(
        id: _string(json['_id'] ?? json['id']),
        nom: _string(json['nom']),
        jours: (json['jours'] as List? ?? const [])
            .map((e) => JourModel.fromJson(_map(e)))
            .toList(),
        actif: json['actif'] == true,
        dateCreation: _date(json['dateCreation']),
        utilisateur: json['utilisateur'] is Map
            ? UserModel.fromJson(_map(json['utilisateur']))
            : null,
      );
  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'nom': nom,
        'jours': jours.map((e) => e.toJson()).toList(),
        'actif': actif,
        if (dateCreation != null)
          'dateCreation': dateCreation!.toIso8601String(),
        if (utilisateur != null) 'utilisateur': utilisateur!.toJson(),
      };
}

class SerieModel {
  const SerieModel({
    required this.numero,
    required this.repetitions,
    required this.charge,
  });
  final int numero;
  final int repetitions;
  final double charge;
  factory SerieModel.fromJson(Map<String, dynamic> json) => SerieModel(
        numero: (json['numero'] as num?)?.toInt() ?? 1,
        repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
        charge: (json['charge'] as num?)?.toDouble() ?? 0,
      );
  Map<String, dynamic> toJson() => {
        'numero': numero,
        'repetitions': repetitions,
        'charge': charge,
      };
}

class ExerciceSeanceModel {
  const ExerciceSeanceModel({
    required this.exerciceId,
    this.series = const [],
    this.tempsRepos = 60,
  });
  final String exerciceId;
  final List<SerieModel> series;
  final int tempsRepos;
  factory ExerciceSeanceModel.fromJson(Map<String, dynamic> json) =>
      ExerciceSeanceModel(
        exerciceId: _string(json['exerciceId']),
        series: (json['series'] as List? ?? const [])
            .map((e) => SerieModel.fromJson(_map(e)))
            .toList(),
        tempsRepos: (json['tempsRepos'] as num?)?.toInt() ?? 60,
      );
  Map<String, dynamic> toJson() => {
        'exerciceId': exerciceId,
        'series': series.map((e) => e.toJson()).toList(),
        'tempsRepos': tempsRepos,
      };
}

class SeanceModel {
  const SeanceModel({
    required this.id,
    this.date,
    this.exercices = const [],
    this.statut = 'brouillon',
    this.valideeLe,
    this.utilisateur,
  });
  final String id;
  final DateTime? date;
  final List<ExerciceSeanceModel> exercices;
  final String statut;
  final DateTime? valideeLe;
  final UserModel? utilisateur;
  factory SeanceModel.fromJson(Map<String, dynamic> json) => SeanceModel(
        id: _string(json['_id'] ?? json['id']),
        date: _date(json['date']),
        exercices: (json['exercices'] as List? ?? const [])
            .map((e) => ExerciceSeanceModel.fromJson(_map(e)))
            .toList(),
        statut: _string(json['statut']).isEmpty
            ? 'brouillon'
            : _string(json['statut']),
        valideeLe: _date(json['valideeLe']),
        utilisateur: json['utilisateur'] is Map
            ? UserModel.fromJson(_map(json['utilisateur']))
            : null,
      );
  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        if (date != null) 'date': date!.toIso8601String(),
        'exercices': exercices.map((e) => e.toJson()).toList(),
      };
}

class QuestionMotivationModel {
  const QuestionMotivationModel({
    required this.question,
    required this.reponse,
  });
  final String question;
  final String reponse;
  factory QuestionMotivationModel.fromJson(Map<String, dynamic> json) =>
      QuestionMotivationModel(
        question: _string(json['question']),
        reponse: _string(json['reponse']),
      );
  Map<String, dynamic> toJson() => {'question': question, 'reponse': reponse};
}

class ObjectifModel {
  const ObjectifModel({
    required this.id,
    required this.type,
    this.valeurCible,
    this.questionsMotivation = const [],
    this.statut = 'en_cours',
    this.dateCreation,
    this.dateCible,
    this.utilisateur,
  });
  final String id;
  final String type;
  final double? valeurCible;
  final List<QuestionMotivationModel> questionsMotivation;
  final String statut;
  final DateTime? dateCreation;
  final DateTime? dateCible;
  final UserModel? utilisateur;
  factory ObjectifModel.fromJson(Map<String, dynamic> json) => ObjectifModel(
        id: _string(json['_id'] ?? json['id']),
        type: _string(json['type']),
        valeurCible: (json['valeurCible'] as num?)?.toDouble(),
        questionsMotivation: (json['questionsMotivation'] as List? ?? const [])
            .map((e) => QuestionMotivationModel.fromJson(_map(e)))
            .toList(),
        statut: _string(json['statut']).isEmpty
            ? 'en_cours'
            : _string(json['statut']),
        dateCreation: _date(json['dateCreation']),
        dateCible: _date(json['dateCible']),
        utilisateur: json['utilisateur'] is Map
            ? UserModel.fromJson(_map(json['utilisateur']))
            : null,
      );
  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'type': type,
        if (valeurCible != null) 'valeurCible': valeurCible,
        'questionsMotivation':
            questionsMotivation.map((e) => e.toJson()).toList(),
        'statut': statut,
        if (dateCreation != null)
          'dateCreation': dateCreation!.toIso8601String(),
        if (dateCible != null) 'dateCible': dateCible!.toIso8601String(),
      };
}

class SuccesModel {
  const SuccesModel({
    required this.id,
    required this.dateObtention,
    required this.description,
    this.utilisateur,
    this.objectif,
  });
  final String id;
  final DateTime? dateObtention;
  final String description;
  final UserModel? utilisateur;
  final ObjectifModel? objectif;
  factory SuccesModel.fromJson(Map<String, dynamic> json) => SuccesModel(
        id: _string(json['_id'] ?? json['id']),
        dateObtention: _date(json['dateObtention']),
        description: _string(json['description']),
        utilisateur: json['utilisateur'] is Map
            ? UserModel.fromJson(_map(json['utilisateur']))
            : null,
        objectif: json['objectif'] is Map
            ? ObjectifModel.fromJson(_map(json['objectif']))
            : null,
      );
  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        if (dateObtention != null)
          'dateObtention': dateObtention!.toIso8601String(),
        'description': description,
        if (utilisateur != null) 'utilisateur': utilisateur!.toJson(),
        if (objectif != null) 'objectif': objectif!.toJson(),
      };
}

class ProgrammeInput {
  const ProgrammeInput({
    required this.nom,
    this.jours = const [],
    this.actif = false,
  });
  final String nom;
  final List<JourModel> jours;
  final bool actif;
  Map<String, dynamic> toJson() => {
        'nom': nom,
        'jours': jours.map((e) => e.toJson()).toList(),
        'actif': actif,
      };
}

class SeanceInput {
  const SeanceInput({this.date, this.exercices = const []});
  final DateTime? date;
  final List<ExerciceSeanceModel> exercices;
  Map<String, dynamic> toJson() => {
        if (date != null) 'date': date!.toIso8601String(),
        'exercices': exercices.map((e) => e.toJson()).toList(),
      };
}

class ObjectifInput {
  const ObjectifInput({
    required this.type,
    this.valeurCible,
    this.dateCible,
    this.statut,
    this.reponses = const [],
  });
  final String type;
  final double? valeurCible;
  final DateTime? dateCible;
  final String? statut;
  final List<String> reponses;
  Map<String, dynamic> toJson() => {
        'type': type,
        if (valeurCible != null) 'valeurCible': valeurCible,
        if (dateCible != null) 'dateCible': dateCible!.toIso8601String(),
        if (statut != null) 'statut': statut,
        'reponses': reponses,
      };
}
