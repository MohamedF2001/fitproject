import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_mobile_flutter/core/models/models.dart';
import 'package:fittrack_mobile_flutter/features/workouts/domain/last_sets.dart';

void main() {
  group('LastSets.forExercise', () {
    test('Historique vide renvoie null', () {
      final result = LastSets.forExercise(['pec-001'], []);
      expect(result, isNull);
    });

    test('Exercice jamais fait renvoie null', () {
      final seance = SeanceModel(
        id: 's1',
        statut: 'validee',
        valideeLe: DateTime(2025, 1, 10),
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'dos-001',
            series: [SerieModel(numero: 1, repetitions: 10, charge: 50)],
          ),
        ],
      );

      final result = LastSets.forExercise(['pec-001'], [seance]);
      expect(result, isNull);
    });

    test('Séance brouillon est ignorée', () {
      final brouillon = SeanceModel(
        id: 's1',
        statut: 'brouillon',
        valideeLe: DateTime(2025, 1, 10),
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [SerieModel(numero: 1, repetitions: 10, charge: 80)],
          ),
        ],
      );

      final result = LastSets.forExercise(['pec-001'], [brouillon]);
      expect(result, isNull);
    });

    test('Tri par date la plus récente quel que soit l\'ordre dans la liste', () {
      final ancienne = SeanceModel(
        id: 's1',
        statut: 'validee',
        valideeLe: DateTime(2025, 1, 1),
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [SerieModel(numero: 1, repetitions: 10, charge: 70)],
          ),
        ],
      );
      final recente = SeanceModel(
        id: 's2',
        statut: 'validee',
        valideeLe: DateTime(2025, 1, 15),
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [SerieModel(numero: 1, repetitions: 8, charge: 80)],
          ),
        ],
      );

      // On passe ancienne puis récente
      final result1 = LastSets.forExercise(['pec-001'], [ancienne, recente]);
      expect(result1, isNotNull);
      expect(result1!.first.charge, 80);

      // On passe récente puis ancienne
      final result2 = LastSets.forExercise(['pec-001'], [recente, ancienne]);
      expect(result2, isNotNull);
      expect(result2!.first.charge, 80);
    });

    test('Repli sur date si valideeLe est null', () {
      final seance = SeanceModel(
        id: 's1',
        statut: 'validee',
        date: DateTime(2025, 1, 12),
        valideeLe: null,
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [SerieModel(numero: 1, repetitions: 10, charge: 75)],
          ),
        ],
      );

      final result = LastSets.forExercise(['pec-001'], [seance]);
      expect(result, isNotNull);
      expect(result!.first.charge, 75);
    });

    test('Une séance sans date perd contre une séance datée', () {
      final sansDate = SeanceModel(
        id: 's1',
        statut: 'validee',
        date: null,
        valideeLe: null,
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [SerieModel(numero: 1, repetitions: 10, charge: 60)],
          ),
        ],
      );

      final datee = SeanceModel(
        id: 's2',
        statut: 'validee',
        date: DateTime(2024, 1, 1),
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [SerieModel(numero: 1, repetitions: 10, charge: 90)],
          ),
        ],
      );

      final result = LastSets.forExercise(['pec-001'], [sansDate, datee]);
      expect(result, isNotNull);
      expect(result!.first.charge, 90);
    });

    test('Support des identifiants multiples (id et uuid)', () {
      final seance = SeanceModel(
        id: 's1',
        statut: 'validee',
        valideeLe: DateTime(2025, 1, 10),
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'a1b2c3d4-0001-4000-8000-000000000001', // uuid
            series: [SerieModel(numero: 1, repetitions: 10, charge: 100)],
          ),
        ],
      );

      final result = LastSets.forExercise(
        ['pec-001', 'a1b2c3d4-0001-4000-8000-000000000001'],
        [seance],
      );
      expect(result, isNotNull);
      expect(result!.first.charge, 100);
    });

    test('Séance sans série pour l\'exercice est sautée', () {
      final seanceSansSerie = SeanceModel(
        id: 's1',
        statut: 'validee',
        valideeLe: DateTime(2025, 1, 20),
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [],
          ),
        ],
      );

      final seanceAncienneAvecSeries = SeanceModel(
        id: 's2',
        statut: 'validee',
        valideeLe: DateTime(2025, 1, 10),
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [SerieModel(numero: 1, repetitions: 10, charge: 70)],
          ),
        ],
      );

      final result = LastSets.forExercise(
        ['pec-001'],
        [seanceSansSerie, seanceAncienneAvecSeries],
      );
      expect(result, isNotNull);
      expect(result!.first.charge, 70);
    });

    test('Renumérotation des séries de 1 à n', () {
      final seance = SeanceModel(
        id: 's1',
        statut: 'validee',
        valideeLe: DateTime(2025, 1, 10),
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [
              SerieModel(numero: 5, repetitions: 10, charge: 80),
              SerieModel(numero: 8, repetitions: 8, charge: 85),
            ],
          ),
        ],
      );

      final result = LastSets.forExercise(['pec-001'], [seance]);
      expect(result, isNotNull);
      expect(result![0].numero, 1);
      expect(result[1].numero, 2);
    });

    test('Première occurrence dans la séance retenue si présent plusieurs fois', () {
      final seance = SeanceModel(
        id: 's1',
        statut: 'validee',
        valideeLe: DateTime(2025, 1, 10),
        exercices: const [
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [SerieModel(numero: 1, repetitions: 10, charge: 60)],
          ),
          ExerciceSeanceModel(
            exerciceId: 'pec-001',
            series: [SerieModel(numero: 1, repetitions: 8, charge: 90)],
          ),
        ],
      );

      final result = LastSets.forExercise(['pec-001'], [seance]);
      expect(result, isNotNull);
      expect(result!.first.charge, 60);
    });
  });

  group('LastSets.topSet', () {
    test('Extrait la série la plus lourde', () {
      const sets = [
        SerieModel(numero: 1, repetitions: 10, charge: 60),
        SerieModel(numero: 2, repetitions: 8, charge: 80),
        SerieModel(numero: 3, repetitions: 6, charge: 70),
      ];

      final top = LastSets.topSet(sets);
      expect(top, isNotNull);
      expect(top!.charge, 80);
      expect(top.repetitions, 8);
    });

    test('À charge égale, retient celle avec le plus de répétitions', () {
      const sets = [
        SerieModel(numero: 1, repetitions: 8, charge: 80),
        SerieModel(numero: 2, repetitions: 10, charge: 80),
      ];

      final top = LastSets.topSet(sets);
      expect(top, isNotNull);
      expect(top!.charge, 80);
      expect(top.repetitions, 10);
    });

    test('Liste vide renvoie null', () {
      expect(LastSets.topSet([]), isNull);
    });
  });

  group('LastSets.summarize', () {
    test('Séries identiques avec charge > 0', () {
      const sets = [
        SerieModel(numero: 1, repetitions: 8, charge: 60),
        SerieModel(numero: 2, repetitions: 8, charge: 60),
        SerieModel(numero: 3, repetitions: 8, charge: 60),
      ];

      expect(LastSets.summarize(sets), '3 × 8 à 60 kg');
    });

    test('Séries différentes', () {
      const sets = [
        SerieModel(numero: 1, repetitions: 8, charge: 60),
        SerieModel(numero: 2, repetitions: 6, charge: 65),
      ];

      expect(LastSets.summarize(sets), '8 × 60 kg, 6 × 65 kg');
    });

    test('Charge à 0 omise', () {
      const sets = [
        SerieModel(numero: 1, repetitions: 12, charge: 0),
        SerieModel(numero: 2, repetitions: 12, charge: 0),
      ];

      expect(LastSets.summarize(sets), '2 × 12');
    });

    test('Liste vide renvoie chaine vide', () {
      expect(LastSets.summarize([]), '');
    });
  });

  group('LastSets.formatKg', () {
    test('Formate les nombres entiers sans zéro superflu', () {
      expect(LastSets.formatKg(60.0), '60');
      expect(LastSets.formatKg(0.0), '0');
    });

    test('Formate les nombres décimaux', () {
      expect(LastSets.formatKg(62.5), '62.5');
    });
  });
}
