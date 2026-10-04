import 'package:fittrack_mobile_flutter/core/models/models.dart';

/// Service de gestion et de recherche des dernières séries enregistrées pour un exercice.
class LastSets {
  /// Recherche les dernières séries validées d'un exercice parmi un historique de séances.
  ///
  /// - Ne prend en compte que les séances avec `statut == 'validee'`.
  /// - Filtre par identifiants d'exercice [exerciceIds] (ex: id ou uuid).
  /// - Trie par date la plus récente (`valideeLe`, sinon `date`).
  /// - Renvoie les séries renumérotées de 1 à n, ou `null` si aucun historique n'est trouvé.
  static List<SerieModel>? forExercise(
    Iterable<String> exerciceIds,
    Iterable<SeanceModel> seances,
  ) {
    final validIds = exerciceIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    if (validIds.isEmpty) return null;

    final validatedSeances = seances.where((s) => s.statut == 'validee').toList();
    if (validatedSeances.isEmpty) return null;

    validatedSeances.sort((a, b) {
      final dateA = a.valideeLe ?? a.date;
      final dateB = b.valideeLe ?? b.date;
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA);
      }
      if (dateA != null) return -1;
      if (dateB != null) return 1;
      return 0;
    });

    for (final seance in validatedSeances) {
      ExerciceSeanceModel? match;
      for (final ex in seance.exercices) {
        if (validIds.contains(ex.exerciceId) && ex.series.isNotEmpty) {
          match = ex;
          break; // Première occurrence dans la séance
        }
      }

      if (match != null) {
        final renumbered = <SerieModel>[];
        for (int i = 0; i < match.series.length; i++) {
          final s = match.series[i];
          renumbered.add(
            SerieModel(
              numero: i + 1,
              repetitions: s.repetitions,
              charge: s.charge,
            ),
          );
        }
        return renumbered.isEmpty ? null : renumbered;
      }
    }

    return null;
  }

  /// Extrait la série la plus lourde (ou la plus répétée à charge égale).
  ///
  /// Retourne `null` si la liste est vide.
  static SerieModel? topSet(List<SerieModel> sets) {
    if (sets.isEmpty) return null;

    SerieModel best = sets.first;
    for (int i = 1; i < sets.length; i++) {
      final current = sets[i];
      if (current.charge > best.charge) {
        best = current;
      } else if (current.charge == best.charge && current.repetitions > best.repetitions) {
        best = current;
      }
    }

    return best;
  }

  /// Résume une liste de séries sous forme de texte lisible.
  ///
  /// Exemple : `"3 × 8 à 60 kg"` si toutes identiques, sinon `"8 × 60 kg, 6 × 65 kg"`.
  /// Si la charge est 0, elle est omise (ex: `"2 × 12"` ou `"12, 10"`).
  /// Retourne `""` si la liste est vide.
  static String summarize(List<SerieModel> sets) {
    if (sets.isEmpty) return '';

    final first = sets.first;
    final allIdentical = sets.every(
      (s) => s.repetitions == first.repetitions && s.charge == first.charge,
    );

    if (allIdentical) {
      final count = sets.length;
      if (first.charge == 0) {
        return '$count × ${first.repetitions}';
      }
      return '$count × ${first.repetitions} à ${formatKg(first.charge)} kg';
    }

    final parts = sets.map((s) {
      if (s.charge == 0) {
        return '${s.repetitions}';
      }
      return '${s.repetitions} × ${formatKg(s.charge)} kg';
    });

    return parts.join(', ');
  }

  /// Formate une valeur de charge en chaîne sans zéro inutile.
  ///
  /// `60` -> `"60"`, `62.5` -> `"62.5"`, `0` -> `"0"`.
  static String formatKg(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
