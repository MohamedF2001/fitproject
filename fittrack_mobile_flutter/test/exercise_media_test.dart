import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_mobile_flutter/core/models/models.dart';
import 'package:fittrack_mobile_flutter/features/exercises/domain/exercise_media.dart';
import 'package:fittrack_mobile_flutter/shared/widgets/exercise_media_widgets.dart';

void main() {
  group('ExerciseMedia.pathsFor & Fichiers sur disque', () {
    test('Chaque identifiant de availableIds renvoie exactement 2 chemins existants sur disque', () {
      expect(ExerciseMedia.availableIds.length, 15);

      for (final id in ExerciseMedia.availableIds) {
        final paths = ExerciseMedia.pathsFor(id);
        expect(paths.length, 2, reason: 'L\'exercice $id doit avoir exactement 2 chemins');

        for (final path in paths) {
          final file = File(path);
          expect(file.existsSync(), isTrue, reason: 'Le fichier $path doit exister sur disque');
        }
      }
    });

    test('pathsFor renvoie [] pour un id inconnu ou vide', () {
      expect(ExerciseMedia.pathsFor(''), isEmpty);
      expect(ExerciseMedia.pathsFor('inconnu'), isEmpty);
      expect(ExerciseMedia.pathsFor('   '), isEmpty);
    });
  });

  group('ExerciseMedia.canonicalId', () {
    const exercises = [
      ExerciceModel(
        id: 'pec-001',
        uuid: 'a1b2c3d4-0001-4000-8000-000000000001',
        nameFr: 'Développé couché barre',
      ),
      ExerciceModel(
        id: 'dos-001',
        uuid: 'a1b2c3d4-0002-4000-8000-000000000001',
        nameFr: 'Tractions',
      ),
    ];

    test('Résout un id', () {
      expect(ExerciseMedia.canonicalId('pec-001', exercises), 'pec-001');
    });

    test('Résout un uuid', () {
      expect(
        ExerciseMedia.canonicalId('a1b2c3d4-0001-4000-8000-000000000001', exercises),
        'pec-001',
      );
    });

    test('Résout directement un id connu dans availableIds sans la liste', () {
      expect(ExerciseMedia.canonicalId('dos-002', const []), 'dos-002');
    });

    test('Renvoie null pour une valeur inconnue ou vide', () {
      expect(ExerciseMedia.canonicalId('', exercises), isNull);
      expect(ExerciseMedia.canonicalId('inconnu-123', exercises), isNull);
    });
  });

  group('Déclaration pubspec.yaml', () {
    test('pubspec.yaml contient la déclaration du dossier assets/exercises/', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);

      final content = pubspecFile.readAsStringSync();
      expect(content.contains('assets/exercises/'), isTrue);
    });
  });

  group('ExerciseThumb Widget Tests', () {
    testWidgets('ExerciseThumb avec id inconnu affiche l\'icône de remplacement', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseThumb(exerciseId: 'inconnu'),
          ),
        ),
      );

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('ExerciseThumb avec id connu contient un widget Image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseThumb(exerciseId: 'pec-001'),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
