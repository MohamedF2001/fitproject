import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_mobile_flutter/core/models/models.dart';
import 'package:fittrack_mobile_flutter/core/utils/one_rm.dart';

void main() {
  group('OneRepMax.estimate - Vecteurs de test imposés', () {
    test('100 kg x 5 reps', () {
      expect(OneRepMax.estimate(100, 5, formula: OneRmFormula.epley), 116.7);
      expect(OneRepMax.estimate(100, 5, formula: OneRmFormula.brzycki), 112.5);
      expect(OneRepMax.estimate(100, 5, formula: OneRmFormula.lombardi), 117.5);
    });

    test('100 kg x 3 reps', () {
      expect(OneRepMax.estimate(100, 3, formula: OneRmFormula.epley), 110.0);
      expect(OneRepMax.estimate(100, 3, formula: OneRmFormula.brzycki), 105.9);
      expect(OneRepMax.estimate(100, 3, formula: OneRmFormula.lombardi), 111.6);
    });

    test('100 kg x 12 reps', () {
      expect(OneRepMax.estimate(100, 12, formula: OneRmFormula.epley), 140.0);
      expect(OneRepMax.estimate(100, 12, formula: OneRmFormula.brzycki), 144.0);
      expect(OneRepMax.estimate(100, 12, formula: OneRmFormula.lombardi), 128.2);
    });

    test('90 kg x 8 reps', () {
      expect(OneRepMax.estimate(90, 8, formula: OneRmFormula.epley), 114.0);
      expect(OneRepMax.estimate(90, 8, formula: OneRmFormula.brzycki), 111.7);
      expect(OneRepMax.estimate(90, 8, formula: OneRmFormula.lombardi), 110.8);
    });

    test('80 kg x 8 reps', () {
      expect(OneRepMax.estimate(80, 8, formula: OneRmFormula.epley), 101.3);
      expect(OneRepMax.estimate(80, 8, formula: OneRmFormula.brzycki), 99.3);
      expect(OneRepMax.estimate(80, 8, formula: OneRmFormula.lombardi), 98.5);
    });

    test('100 kg x 10 reps', () {
      expect(OneRepMax.estimate(100, 10, formula: OneRmFormula.epley), 133.3);
      expect(OneRepMax.estimate(100, 10, formula: OneRmFormula.brzycki), 133.3);
      expect(OneRepMax.estimate(100, 10, formula: OneRmFormula.lombardi), 125.9);
    });

    test('140 kg x 1 rep', () {
      expect(OneRepMax.estimate(140, 1, formula: OneRmFormula.epley), 140.0);
      expect(OneRepMax.estimate(140, 1, formula: OneRmFormula.brzycki), 140.0);
      expect(OneRepMax.estimate(140, 1, formula: OneRmFormula.lombardi), 140.0);
    });
  });

  group('OneRepMax.estimate - Cas limites', () {
    test('13 répétitions (au-dessus du cap de 12) renvoie null', () {
      expect(OneRepMax.estimate(100, 13), isNull);
    });

    test('12 répétitions renvoie une valeur', () {
      expect(OneRepMax.estimate(100, 12), isNotNull);
    });

    test('Charges invalides (0, négative, NaN, infinie) renvoient null', () {
      expect(OneRepMax.estimate(0, 10), isNull);
      expect(OneRepMax.estimate(-50, 10), isNull);
      expect(OneRepMax.estimate(double.nan, 10), isNull);
      expect(OneRepMax.estimate(double.infinity, 10), isNull);
    });

    test('Répétitions invalides (0 ou négatif) renvoient null', () {
      expect(OneRepMax.estimate(100, 0), isNull);
      expect(OneRepMax.estimate(100, -5), isNull);
    });
  });

  group('OneRepMax.bestOfSets', () {
    test('Retient la meilleure estimation (90 kg x 8 reps > 100 kg x 3 reps avec Epley)', () {
      const set1 = SerieModel(numero: 1, repetitions: 3, charge: 100); // 110.0
      const set2 = SerieModel(numero: 2, repetitions: 8, charge: 90);   // 114.0

      final best = OneRepMax.bestOfSets([set1, set2]);
      expect(best, isNotNull);
      expect(best!.value, 114.0);
      expect(best.weight, 90.0);
      expect(best.reps, 8);
    });

    test('Ignore les séries non exploitables (reps > 12 ou charge == 0)', () {
      const setInvalideReps = SerieModel(numero: 1, repetitions: 15, charge: 40);
      const setPoidsDuCorps = SerieModel(numero: 2, repetitions: 10, charge: 0);
      const setValide = SerieModel(numero: 3, repetitions: 5, charge: 100);

      final best = OneRepMax.bestOfSets([
        setInvalideReps,
        setPoidsDuCorps,
        setValide,
      ]);

      expect(best, isNotNull);
      expect(best!.value, 116.7);
      expect(best.weight, 100.0);
    });

    test('Retourne null si la liste de séries est vide', () {
      expect(OneRepMax.bestOfSets([]), isNull);
    });

    test('En cas d\'égalité, la première série l\'emporte', () {
      const setA = SerieModel(numero: 1, repetitions: 5, charge: 100); // 116.7
      const setB = SerieModel(numero: 2, repetitions: 5, charge: 100); // 116.7

      final best = OneRepMax.bestOfSets([setA, setB]);
      expect(best, isNotNull);
      expect(best!.weight, 100.0);
      expect(best.reps, 5);
      expect(best.value, 116.7);
    });
  });
}
