import 'dart:math';
import 'package:fittrack_mobile_flutter/core/models/models.dart';

/// Formules disponibles pour l'estimation du 1RM.
enum OneRmFormula { epley, brzycki, lombardi }

/// Résultat d'une estimation du 1RM associée à une série spécifique.
class OneRmEstimate {
  final double value;
  final double weight;
  final int reps;

  const OneRmEstimate({
    required this.value,
    required this.weight,
    required this.reps,
  });
}

/// Classe utilitaire pour le calcul du 1RM (1 Repetition Maximum).
class OneRepMax {
  /// Plafond de répétitions au-delà duquel l'estimation n'est plus fiable.
  static const int repCap = 12;

  /// Formule d'estimation par défaut.
  static const OneRmFormula defaultFormula = OneRmFormula.epley;

  /// Calcule l'estimation du 1RM pour un poids et un nombre de répétitions donnés.
  ///
  /// Retourne `null` si le poids est <= 0, si la valeur est non finie, ou si
  /// les répétitions sont inférieures à 1 ou supérieures à [repCap].
  static double? estimate(
    double weight,
    int reps, {
    OneRmFormula formula = defaultFormula,
  }) {
    if (weight <= 0 || !weight.isFinite) return null;
    if (reps < 1 || reps > repCap) return null;

    if (reps == 1) {
      return (weight * 10).round() / 10;
    }

    double raw;
    switch (formula) {
      case OneRmFormula.epley:
        raw = weight * (1.0 + reps / 30.0);
        break;
      case OneRmFormula.brzycki:
        raw = weight * 36.0 / (37.0 - reps);
        break;
      case OneRmFormula.lombardi:
        raw = weight * pow(reps, 0.10);
        break;
    }

    if (!raw.isFinite) return null;
    return (raw * 10).round() / 10;
  }

  /// Recherche la meilleure estimation de 1RM parmi une liste de séries.
  ///
  /// Les séries non exploitables (poids <= 0, reps > 12, etc.) sont ignorées.
  /// En cas d'égalité stricte, la première série l'emporte.
  /// Retourne `null` si aucune série n'est exploitable.
  static OneRmEstimate? bestOfSets(
    Iterable<SerieModel> sets, {
    OneRmFormula formula = defaultFormula,
  }) {
    OneRmEstimate? best;

    for (final set in sets) {
      final estVal = estimate(set.charge, set.repetitions, formula: formula);
      if (estVal != null) {
        if (best == null || estVal > best.value) {
          best = OneRmEstimate(
            value: estVal,
            weight: set.charge,
            reps: set.repetitions,
          );
        }
      }
    }

    return best;
  }
}
