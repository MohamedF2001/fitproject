import 'package:fittrack_mobile_flutter/core/models/models.dart';

/// Service de résolution des médias et images associés aux exercices.
class ExerciseMedia {
  static const String basePath = 'assets/exercises';

  /// Ensemble des identifiants FitTrack pour lesquels des photos sont embarquées.
  static const Set<String> availableIds = {
    'pec-001',
    'pec-002',
    'pec-003',
    'dos-001',
    'dos-002',
    'dos-003',
    'jam-001',
    'jam-002',
    'jam-003',
    'epa-001',
    'epa-002',
    'bra-001',
    'bra-002',
    'abd-001',
    'abd-002',
  };

  /// Renvoie la liste des chemins d'accès aux photos pour un identifiant d'exercice donné.
  ///
  /// Retourne `['assets/exercises/<id>_0.jpg', 'assets/exercises/<id>_1.jpg']`
  /// ou une liste vide `[]` si l'identifiant est inconnu ou vide.
  static List<String> pathsFor(String exerciseId) {
    final cleanId = exerciseId.trim();
    if (cleanId.isEmpty || !availableIds.contains(cleanId)) {
      return const [];
    }
    return [
      '$basePath/${cleanId}_0.jpg',
      '$basePath/${cleanId}_1.jpg',
    ];
  }

  /// Résout un identifiant (`id` ou `uuid`) vers l'identifiant canonique de l'exercice.
  ///
  /// Renvoie `null` si la valeur est vide ou introuvable dans la liste [exercises].
  static String? canonicalId(String idOrUuid, Iterable<ExerciceModel> exercises) {
    final clean = idOrUuid.trim();
    if (clean.isEmpty) return null;

    for (final ex in exercises) {
      if (ex.id == clean || ex.uuid == clean) {
        return ex.id;
      }
    }

    if (availableIds.contains(clean)) {
      return clean;
    }

    return null;
  }
}
