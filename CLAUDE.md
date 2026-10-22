# Context & Guide de Développement — FitTrack

## 1. Ce qu'est le projet

FitTrack est une application mobile de suivi de musculation en français.
Le projet est composé d'une application mobile Flutter (`fittrack_mobile_flutter/`) communiquant via une API REST avec un backend Node.js / Express / MongoDB Atlas (`fittrack-backend/`).

## 2. Disposition du dépôt

- `fittrack_mobile_flutter/` : Application mobile Flutter (Dart 3.5+, Riverpod, GoRouter, Hive, Retrofit/Dio).
- `fittrack-backend/` : API REST Backend Node.js / Express / Mongoose.
- `stitch_fittrack_mobile_app/` : Exports et maquettes visuelles de l'application.
- `openGym/` : Projet open-source tiers conservé comme source d'inspiration produit (attention aux règles de licence AGPL-3.0).
- `BRIEF_IA_FitTrack_openGym.md` : Brief fonctionnel et spécifications techniques de référence.
- `Prompt_Generation_FitTrack_Mobile_Flutter_v2.md` & `prompt_backend_fittrack2.md` : Prompts historiques et spécifications d'origine.

## 3. Commandes principales

### Application Mobile (`fittrack_mobile_flutter/`)
- Installation des dépendances : `flutter pub get`
- Génération du code (Freezed / Retrofit / JSON) : `dart run build_runner build --delete-conflicting-outputs`
- Exécution des tests unitaires et de widgets : `flutter test`
- Analyse statique du code : `flutter analyze`
- Exécution du script de téléchargement des images : `bash scripts/fetch_exercise_media.sh`

### API Backend (`fittrack-backend/`)
- Installation des dépendances : `npm install`
- Démarrage du serveur backend : `npm start` ou `npm run dev` (tourne sur `http://localhost:3000`)

## 4. Architecture mobile

L'application mobile suit une Clean Architecture structurée par fonctionnalité (*feature*) :

- `lib/core/` : Constantes (`AppColors`, `AppSpacing`), erreurs (`Failure`), modèles immuables (`models.dart`), réseau (`DioClient`), providers Riverpod globaux (`app_providers.dart`), stockage local (`local_storage.dart`), thème (`app_theme.dart`), utilitaires pures (`one_rm.dart`).
- `lib/features/` : Modules fonctionnels (`auth/`, `exercises/`, `workouts/`, `programs/`, `goals/`, `settings/`, `achievements/`). Chaque module contient :
  - `data/` : Datasources Dio/Retrofit, modèles DTO et implémentations de repositories.
  - `domain/` : Entités métier, interfaces de repositories et fonctions/usecases pures (`last_sets.dart`, `exercise_media.dart`).
  - `presentation/` : Pages UI Flutter, widgets spécifiques, providers Riverpod d'écran.
- `lib/shared/` : Widgets réutilisables (`app_shell.dart`, `charts.dart`, `exercise_media_widgets.dart`).

**Stockage local Hive** : Utilisé pour la persistance du jeton d'authentification JWT, des informations de l'utilisateur connecté, et des caches d'exercices et du programme actif.

## 5. Modèle de données

Défini dans `fittrack_mobile_flutter/lib/core/models/models.dart` et côté backend dans `fittrack-backend/models/`.

```dart
class SerieModel {
  final int numero;     // 1..n
  final int repetitions;
  final double charge;  // kg ; 0 = poids du corps
}

class ExerciceSeanceModel {
  final String exerciceId; // ATTENTION : peut contenir l'id (ex: 'pec-001') OU l'uuid
  final List<SerieModel> series;
  final int tempsRepos; // secondes, 60 par défaut
}

class SeanceModel {
  final String id;
  final DateTime? date;
  final List<ExerciceSeanceModel> exercices;
  final String statut;       // 'brouillon' | 'validee'
  final DateTime? valideeLe; // null tant que non validée
  final UserModel? utilisateur;
}
```

- **Cycle d'une séance** : `brouillon` → `validee` (`POST /api/seances/:id/valider`). Une séance validée est immuable (retourne HTTP 403 si modification).
- **Piège id / uuid** : Un exercice possède un `id` et un `uuid`. Une séance en historique peut référencer l'un ou l'autre. Toujours utiliser `ExerciseMedia.canonicalId` ou un filtrage multi-identifiants pour la résolution.

### Images d'exercices
- Stockées dans `fittrack_mobile_flutter/assets/exercises/<id>_0.jpg` et `<id>_1.jpg` (30 photos embarquées issues de `free-exercise-db`).
- Déclarées sous `flutter: assets:` dans `pubspec.yaml`.
- Traçabilité et correspondance documentées dans `assets/exercises/NOTICE.md`.
- Résolution dynamique via `ExerciseMedia` et affichage UI via `ExerciseThumb` et `ExerciseDemo`.

## 6. Backend

### Routes API principales (`fittrack-backend/routes/`)
- `/api/auth` : Inscription (`/register`), connexion (`/login`), profil (`/me`).
- `/api/exercices` : Liste des exercices du catalogue français groupés par muscle (`/`).
- `/api/programmes` : Gestion des programmes d'entraînement et sélection du programme actif.
- `/api/seances` : CRUD des séances brouillons et endpoint de validation (`POST /:id/valider`).
- `/api/users` : Historique de poids, objectifs et succès.

### Logique de validation & Goals Checker
À la validation d'une séance (`validerSeance`), le backend exécute `utils/goalsChecker.js` qui calcule la charge maximale sur l'ensemble des séries validées et met à jour les objectifs / débloque les succès.

### Variables d'environnement attendues (`.env`)
- `PORT`
- `MONGO_URI`
- `JWT_SECRET`

*(Remarque : Ne jamais divulguer ni commiter les valeurs réelles de ces variables).*

## 7. Conventions de code

- Interface et champs JSON d'API en français (`name_fr`, `description_fr`, `tempsRepos`, `valideeLe`), identifiants de code Dart/JS en anglais pour la structure.
- **Logique pure et testée** : Toute fonction décidant d'une valeur calculée ou suggérée (1RM, préremplissage, PR, progression) doit être une **fonction pure** située dans `core/utils/` ou `features/*/domain/`, couverte par des tests unitaires.
- **Règles UI** : Pas de logique métier complexe directe dans les pages Flutter. Ne pas alourdir `workout_page.dart`.

## 8. Règles à ne pas enfreindre

- **Secrets** : Ne jamais commiter de fichiers d'environnement (`.env`), de clés d'API ou de secrets.
- **Hygiène Git** : Ne jamais commiter `node_modules/`, `.idea/`, `build/`, `.dart_tool/` ou des artefacts générés.
- **Licence AGPL-3.0 (openGym)** : Ne jamais copier ni traduire de code provenant d'openGym. Réimplémenter à partir de formules publiques et de spécifications originales.
- **Images d'exercices** : N'ajouter des images d'exercices que si leur licence est libre et documentée dans `assets/exercises/NOTICE.md`.
- **Modèles JSON** : Ne pas altérer la structure des modèles JSON sans adapter simultanément le backend REST API.

## 9. Points faibles connus du dépôt

1. **États de séries complétées non persistés** : Les coches « série faite » (`_completedSets`) dans `workout_page.dart` sont uniquement locales à la vue et ne sont pas enregistrées en base ni transmises.
2. **Volumétrie de `workout_page.dart`** : Fichier monolithique d'environ 1 700 lignes nécessitant un découpage modulaire.
3. **Couverture de tests globale faible** : Hors modules isolés (`one_rm`, `last_sets`, `exercise_media`), la couverture globale de l'UI et des datasources est limitée.
4. **Courbe d'évolution sans 1RM** : Le widget de graphique `ChargeEvolutionGraphWidget` trace uniquement la charge brute max par séance sans inclure l'estimation du 1RM.
5. **Dépendance réseau pour les séances** : Hive ne met pas en cache l'historique complet des séances ; l'application nécessite le réseau pour interroger `workoutsProvider`.
6. **Catalogue d'images limité** : Les images embarquées couvrent uniquement les 15 exercices du catalogue de départ.

## 10. Feuille de route (Roadmap courte)

1. Persistance et envoi de l'état « série réalisée » dans le modèle de séance.
2. Intégration de la courbe 1RM dans `ChargeEvolutionGraphWidget`.
3. Détection automatique des Records Personnels (PR) lors de la validation d'une séance.
4. Moteur de règles de progression (progression linéaire, double progression, suggestions de charge).
5. Refactorisation et découpage modulaire de `workout_page.dart`.
6. Architecture Offline-First pour la consultation et l'édition des séances en local via Hive.
