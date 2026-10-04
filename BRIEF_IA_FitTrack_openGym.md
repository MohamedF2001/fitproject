# Brief pour l'IA — FitTrack : module 1RM, préremplissage, CLAUDE.md et images d'exercices

> **Comment utiliser ce document** : donne-le tel quel à l'IA (Claude Code, Cursor, etc.) avec l'accès au dépôt FitTrack. Il contient tout ce qu'il faut pour produire **trois livrables** :
>
> - **(a)** le module « 1RM estimé + préremplissage depuis la dernière séance » (code Dart + tests) ;
> - **(b)** un fichier `CLAUDE.md` à la racine du dépôt, adapté à FitTrack ;
> - **(c)** les **images d'exercices** (photos libres de droits embarquées dans l'app), avec les règles de licence.
>
> Ordre conseillé : (a), puis (c), puis (b) — le `CLAUDE.md` décrit alors l'état final du dépôt, images comprises.
>
> L'IA doit lire le dépôt avant d'écrire quoi que ce soit, et ne pas deviner ce qui n'est pas dans ce brief.

---

## 1. Le projet

- **Dépôt** : `github.com/MohamedF2001/fitproject`
- **Branche de travail** : `feature/fittrack-charge-graph-weight-tracking-6834993547198699457`
- **Nature** : application de suivi de musculation (FitTrack), en français.

| Partie | Dossier | Technologies |
|---|---|---|
| Mobile | `fittrack_mobile_flutter/` | Flutter (SDK Dart `>=3.5.0 <4.0.0`), Riverpod (`flutter_riverpod`), `go_router`, Hive, Dio + Retrofit, Freezed / json_serializable (déclarés), `intl` |
| Backend | `fittrack-backend/` | Node.js, Express, Mongoose (MongoDB Atlas), authentification JWT, Swagger |
| Maquettes | `stitch_fittrack_mobile_app/` | Écrans exportés (accueil, séance en cours, objectifs, évolution, etc.) |
| Prompts historiques | `Prompt_Generation_FitTrack_Mobile_Flutter_v2.md`, `prompt_backend_fittrack2.md` | Spécifications d'origine, à lire pour le ton et les conventions |

### Arborescence mobile (clean architecture par feature)

```
fittrack_mobile_flutter/lib/
  core/            constants, errors, models (models.dart), network, providers (app_providers.dart),
                   router, storage (local_storage.dart, Hive), theme, utils, widgets
  features/
    auth/  exercises/  programs/  goals/  settings/  workouts/  achievements/
      data/          datasources, models, repositories
      domain/        entities, repositories, usecases
      presentation/  pages, providers, controllers
  shared/          widgets (charts.dart, app_shell.dart), helpers, extensions
  main.dart, app_router.dart
fittrack_mobile_flutter/test/   un seul test existant : widget_test.dart
```

## 2. Modèle de données (à respecter à la lettre)

Défini dans `fittrack_mobile_flutter/lib/core/models/models.dart` (classes immuables, `fromJson` / `toJson` écrits à la main) et côté backend dans `fittrack-backend/models/Seance.js`.

```dart
class SerieModel {            // une série
  final int numero;           // 1..n
  final int repetitions;
  final double charge;        // kg ; 0 = poids du corps ou non renseigné
}
class ExerciceSeanceModel {   // un exercice dans une séance
  final String exerciceId;    // ATTENTION : peut être l'id OU l'uuid de l'exercice
  final List<SerieModel> series;
  final int tempsRepos;       // secondes, 60 par défaut
}
class SeanceModel {
  final String id;
  final DateTime? date;
  final List<ExerciceSeanceModel> exercices;
  final String statut;        // 'brouillon' | 'validee'
  final DateTime? valideeLe;  // null tant que non validée
  final UserModel? utilisateur;
}
```

- Le cycle d'une séance est `brouillon` → `validee` (`POST` de validation, `validerSeance` côté backend). Une séance validée n'est plus modifiable (403).
- `ExerciceModel` a un `id` **et** un `uuid`. L'écran de séance mappe les deux vers le nom français : un historique peut donc référencer l'un ou l'autre.
- La liste des séances vient de `workoutsProvider` (`FutureProvider.autoDispose<List<SeanceModel>>` dans `core/providers/app_providers.dart`).

## 3. État actuel — faits vérifiés dans le dépôt

1. `lib/features/workouts/presentation/pages/workout_page.dart` fait **~1 730 lignes** ; la classe `_WorkoutPageState` en occupe environ 1 300. Aucune logique métier testable n'en est extraite.
2. Quand on charge un jour de programme (`_create()`), les séries sont codées en dur : **3 × 10 répétitions × 0 kg**.
3. Dans la boîte de dialogue « Ajouter un exercice » (`_AddExerciseDialog`), les champs démarrent à `10` répétitions et `0` kg. Le menu « Nombre de séries » n'accepte que `[1, 2, 3, 4, 5, 6, 8, 10]` : **ne jamais lui affecter une autre valeur** (assertion Flutter).
4. `ChargeEvolutionGraphWidget` (`shared/widgets/charts.dart`) trace la **charge maximale par séance validée**, via un `CustomPainter`. Il n'y a aucune notion de 1RM.
5. Le backend (`utils/goalsChecker.js`) calcule la charge maximale sur toutes les séries des séances validées.
6. **Aucun champ « série faite »** n'existe dans le modèle. L'ensemble `_completedSets` de `workout_page.dart` n'est qu'un état d'écran (coches) : il n'est ni persisté, ni envoyé, ni utilisé à la validation. Toutes les séries d'un brouillon comptent donc comme réalisées une fois la séance validée.
7. Couverture de tests quasi nulle : un seul test (`test/widget_test.dart`).
8. Hygiène du dépôt : `fittrack-backend/.env` (avec `MONGO_URI` et `JWT_SECRET`), `node_modules/` et `.idea/` sont commités.
9. **Aucune image d'exercice** : `ExerciceModel` n'a pas de champ image et l'app n'en affiche pas. Le catalogue (`fittrack-backend/data/exercises_by_muscle_fr.json`) ne contient que **15 exercices** (ids `pec-001`, `dos-002`, `jam-001`…), répartis en 6 groupes musculaires.

## 4. Source d'inspiration : openGym

**openGym** (`github.com/DuarteSantos8/openGym`) est un tracker de musculation auto-hébergé (React + Node). On s'en inspire pour **les idées et le comportement**, rien d'autre.

### ⚖️ Règle de licence — impérative

openGym est sous **AGPL-3.0**. Il est **interdit de copier ou de traduire son code** (pas de portage de `onerm.js`, `progression.js`, `finish-workout.js`, etc.), sous peine de rendre FitTrack dérivé d'une œuvre AGPL.

L'IA doit donc :

- écrire le Dart **à partir des formules publiques et du comportement décrit dans ce brief** ;
- ne pas ouvrir le code d'openGym pour le recopier ; la structure, les noms et les commentaires sont à rédiger de façon originale ;
- ne jamais reprendre les médias d'exercices d'openGym (droits contestés) : pour les images, utiliser **uniquement** la source et les règles du livrable (c), section 7.

### Ce qu'on emprunte comme idées

| Idée | Comportement attendu |
|---|---|
| 1RM estimé | À partir d'une série (charge + répétitions) ; Epley par défaut ; plafond à 12 répétitions ; 1 répétition = valeur mesurée ; refuser plutôt qu'inventer |
| Préremplissage | Une nouvelle séance reprend les valeurs de la dernière fois pour chaque exercice |
| Logique pure et testée | Tout ce qui décide d'une valeur affichée ou suggérée est une fonction pure avec des tests unitaires à côté |

## 5. Livrable (a) — 1RM + préremplissage

### 5.1 Fichiers à créer

| Fichier | Rôle |
|---|---|
| `fittrack_mobile_flutter/lib/core/utils/one_rm.dart` | Estimation du 1RM |
| `fittrack_mobile_flutter/lib/features/workouts/domain/last_sets.dart` | Recherche des dernières séries d'un exercice, résumé lisible |
| `fittrack_mobile_flutter/test/one_rm_test.dart` | Tests du 1RM |
| `fittrack_mobile_flutter/test/last_sets_test.dart` | Tests du préremplissage |

Fichier à modifier : `lib/features/workouts/presentation/pages/workout_page.dart` (modifications minimales, voir 5.4).

Conventions : noms de fichiers et de classes en anglais (comme le reste des features), commentaires de documentation en français, `package:` imports dans les tests (`package:fittrack_mobile_flutter/...`). Dart 3 est disponible : records, expressions `switch` autorisés.

### 5.2 `one_rm.dart` — spécification

API attendue :

```dart
enum OneRmFormula { epley, brzycki, lombardi }

class OneRmEstimate { final double value; final double weight; final int reps; }

class OneRepMax {
  static const int repCap = 12;
  static const OneRmFormula defaultFormula = OneRmFormula.epley;
  static double? estimate(double weight, int reps, {OneRmFormula formula = defaultFormula});
  static OneRmEstimate? bestOfSets(Iterable<SerieModel> sets, {OneRmFormula formula = defaultFormula});
}
```

Règles :

- Formules (publiques) :
  - Epley : `w × (1 + r / 30)`
  - Brzycki : `w × 36 / (37 − r)`
  - Lombardi : `w × r^0,10`
- `estimate` retourne **`null`** si : charge `<= 0`, non finie (NaN, infini), `reps < 1` ou `reps > 12`.
- `reps == 1` → renvoie la charge telle quelle, quelle que soit la formule.
- Résultat **arrondi à 0,1** (`(raw * 10).round() / 10`).
- `bestOfSets` : garde la **meilleure estimation** (pas la charge la plus lourde) ; ignore les séries sans estimation possible (poids du corps, plus de 12 répétitions) ; à égalité, la première série l'emporte ; retourne `null` sans série exploitable.

**Vecteurs de test imposés** (calculés indépendamment, à reprendre dans les tests) :

| Charge × reps | Epley | Brzycki | Lombardi |
|---|---|---|---|
| 100 × 5 | 116,7 | 112,5 | 117,5 |
| 100 × 3 | 110,0 | 105,9 | 111,6 |
| 100 × 12 | 140,0 | 144,0 | 128,2 |
| 90 × 8 | 114,0 | 111,7 | 110,8 |
| 80 × 8 | 101,3 | 99,3 | 98,5 |
| 100 × 10 | 133,3 | 133,3 | 125,9 |
| 140 × 1 | 140,0 | 140,0 | 140,0 |

Cas à tester : 13 répétitions → `null` ; 12 → valeur ; charge 0, négative, NaN, infinie → `null` ; `reps` 0 ou négatif → `null` ; `bestOfSets` entre `100 × 3` (110,0) et `90 × 8` (114,0) retient `90 × 8` ; séries `15 × 40 kg` et `10 × 0 kg` ignorées ; liste vide → `null`.

### 5.3 `last_sets.dart` — spécification

API attendue :

```dart
class LastSets {
  static List<SerieModel>? forExercise(Iterable<String> exerciceIds, Iterable<SeanceModel> seances);
  static SerieModel? topSet(List<SerieModel> sets);
  static String summarize(List<SerieModel> sets);
  static String formatKg(double value);
}
```

Règles de `forExercise` :

- Ne considère que les séances `statut == 'validee'` (les brouillons sont ignorés).
- Accepte **plusieurs identifiants** pour un même exercice (`id` et `uuid`) ; ignore les identifiants vides ; aucun identifiant utilisable → `null`.
- Date de référence d'une séance : `valideeLe`, à défaut `date`. Une séance **sans date** perd contre une séance datée. Le résultat ne dépend pas de l'ordre de la liste.
- Une séance où l'exercice n'a **aucune série** est sautée.
- Si l'exercice apparaît deux fois dans la même séance, la **première occurrence** est retenue.
- Retourne des **copies renumérotées de 1 à n**, avec les mêmes répétitions et charges ; `null` s'il n'y a pas d'historique.

Autres fonctions :

- `topSet` : série la plus lourde ; à charge égale, celle qui a le plus de répétitions ; `null` si liste vide.
- `summarize` : `"3 × 8 à 60 kg"` si toutes les séries sont identiques ; sinon `"8 × 60 kg, 6 × 65 kg"` ; charge 0 omise (`"2 × 12"`) ; liste vide → `""`.
- `formatKg` : `60` → `"60"`, `62.5` → `"62.5"`, `0` → `"0"`.

Tests : un test par règle ci-dessus (historique vide, exercice jamais fait, brouillon ignoré, tri par date quel que soit l'ordre, repli sur `date`, séance sans date, identifiants multiples, séance sans série, renumérotation, première occurrence, `topSet`, `summarize`, `formatKg`).

### 5.4 Intégration dans `workout_page.dart` (diff minimal)

1. **Chargement de l'historique** : méthode `_loadHistory()` qui lit `ref.read(workoutsProvider.future)` dans un `try/catch` et renvoie `const []` en cas d'échec (un problème réseau ne doit jamais bloquer le démarrage d'une séance).
2. **`_create()`** : pour chaque exercice du jour de programme choisi, les séries viennent de `LastSets.forExercise([e.exerciceId], history)` ; à défaut, on garde les 3 × 10 × 0 d'origine. Vérifier `mounted` après chaque `await`.
3. **`_addExercise()`** : charger l'historique et le passer à `_AddExerciseDialog` (nouveau paramètre optionnel `history`, par défaut `const []`).
4. **`_AddExerciseDialog`** :
   - à l'ouverture et à chaque changement d'exercice, préremplir **répétitions et charge** avec `LastSets.topSet(...)` ; sans historique, revenir à `10` et `0` ;
   - afficher au-dessus des champs une ligne discrète : `Dernière séance : <summarize> · 1RM estimé ≈ <valeur> kg` (le suffixe 1RM seulement si `OneRepMax.bestOfSets` retourne une valeur) ;
   - **ne pas toucher** à `_numberOfSets` (voir point 3 de la section 3).
5. Style de la ligne d'aide : `TextStyle(color: AppColors.textMuted, fontSize: 12)`.

Ne pas refactorer le reste du fichier dans ce livrable.

## 6. Livrable (b) — `CLAUDE.md` adapté à FitTrack

Fichier à créer à la **racine du dépôt**. Il sert de contexte de départ à chaque session d'assistant IA. Il doit être **court, factuel, vérifié dans le dépôt** (pas de généralités) et rédigé en français. Sections obligatoires :

1. **Ce qu'est le projet** : 3-4 lignes (app de suivi de musculation, mobile Flutter + API Node/Mongo).
2. **Disposition du dépôt** : les dossiers de la section 1, une ligne chacun.
3. **Commandes** : à relever dans `pubspec.yaml`, `package.json` et le `README` du dépôt (au minimum : `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, `flutter test`, `flutter analyze`, démarrage du backend). Ne lister que les commandes qui existent réellement.
4. **Architecture mobile** : clean architecture par feature, rôle de `core/` et `shared/`, flux « page → provider Riverpod → repository → datasource Dio/Retrofit », rôle de Hive (aujourd'hui : token, utilisateur, caches d'exercices et de programme actif).
5. **Modèle de données** : les trois classes de la section 2, le cycle `brouillon → validee`, le piège `id` / `uuid`. Ajouter un paragraphe « Images d'exercices » (dossier `assets/exercises/`, helper `ExerciseMedia`, `NOTICE.md`) une fois (c) réalisé.
6. **Backend** : routes principales (à lire dans `fittrack-backend/routes/`), validation d'une séance et `goalsChecker`, variables d'environnement attendues (**noms uniquement, jamais les valeurs**).
7. **Conventions de code** :
   - interface et champs d'API en français, identifiants de code cohérents avec l'existant ;
   - toute logique qui décide d'une valeur affichée ou suggérée (1RM, préremplissage, progression, PR) est une **fonction pure** dans `core/utils/` ou `features/*/domain/`, avec un test à côté ;
   - pas de nouvelle logique métier dans les pages ; ne pas agrandir `workout_page.dart`.
8. **Règles à ne pas enfreindre** :
   - ne jamais commiter de secret (`.env`, clés) ni `node_modules/`, `.idea/`, `build/`, `.dart_tool/` ;
   - ne jamais copier de code sous licence AGPL (openGym) : réimplémenter à partir de formules publiques et de comportements décrits ;
   - n'ajouter des images d'exercices que si leur licence est libre **et documentée** dans `assets/exercises/NOTICE.md` ;
   - ne pas modifier la forme des modèles JSON sans changer le backend en parallèle.
9. **Points faibles connus** (utile aux futures sessions) : séries non marquées « faites » (point 6 de la section 3), `workout_page.dart` trop volumineux, couverture de tests quasi nulle, courbe de charge sans 1RM, Hive qui ne met pas les séances en cache (l'application exige le réseau pour les séances), images disponibles pour 15 exercices seulement.
10. **Feuille de route courte** : (1) séries « faites » ; (2) courbe 1RM dans `ChargeEvolutionGraphWidget` ; (3) détection de PR ; (4) règles de progression (linéaire, double progression, deload) ; (5) découpage de `workout_page.dart` ; (6) offline-first éventuel.

Le `CLAUDE.md` ne doit contenir **aucune valeur secrète**, même si elle est visible dans le dépôt.

## 7. Livrable (c) — Images d'exercices

### 7.1 Source retenue : free-exercise-db (yuhonas)

- **Dépôt** : `github.com/yuhonas/free-exercise-db` — environ 870 exercices, avec **deux photos JPG** par exercice (`0.jpg` et `1.jpg`, a priori deux positions du mouvement : à confirmer en ouvrant les fichiers).
- **Licence** : **Unlicense** (domaine public). Le fichier `LICENSE.md` du dépôt (relu le 4 octobre 2026) autorise de copier, modifier, publier, utiliser et vendre, à des fins commerciales ou non, sans condition d'attribution.
- **Pourquoi celle-ci** : licence la plus permissive des options examinées, aucune attribution obligatoire, photos légères, et un catalogue FitTrack de 15 exercices qui se met en correspondance à la main en quelques minutes. Les 30 photos retenues pèsent **~1,8 Mo au total** (environ 40 à 85 Ko chacune) : on peut les **embarquer dans l'application**, sans réseau, sans dépendance supplémentaire et sans dépendre d'un service tiers à l'exécution.
- **Limites assumées** : photos fixes (pas de GIF animés comme dans openGym) ; noms d'origine en anglais (on garde les noms français de FitTrack) ; l'illusion de mouvement vient d'une alternance douce entre les deux photos (voir 7.5).

### 7.2 Règles de licence — impératives

1. **Une seule source autorisée** : free-exercise-db. Interdit : les médias d'openGym (`media/`, dataset `hasaneyldrm/exercises-dataset`, ExerciseDB, Gym visual), tout autre site d'images d'exercices, tout scraping, toute image générée ou retrouvée « au hasard » sur le web.
2. **Copie fidèle** : copier les JPG tels quels (renommage seulement). Pas de recadrage, retouche ni recompression dans cette passe.
3. **Traçabilité obligatoire** : créer `fittrack_mobile_flutter/assets/exercises/NOTICE.md` avec :
   - l'URL de la source et le **SHA du commit amont** téléchargé (`git ls-remote https://github.com/yuhonas/free-exercise-db HEAD`) ;
   - la date de téléchargement ;
   - le nom de la licence (Unlicense) et un lien vers son texte ;
   - le **tableau de correspondance** FitTrack → dossier amont (7.3).
4. **Vérification de provenance, à la charge du propriétaire du dépôt** : le dépôt amont déclare le domaine public, mais la provenance des photos n'a pas été auditée de façon indépendante. Pour un projet livré à un client commercial, le propriétaire décide s'il accepte ce risque. L'IA ne tranche pas et le signale dans `NOTICE.md` (« provenance déclarée par le dépôt amont, non auditée »).
5. **Remplaçable en un seul endroit** : tous les chemins d'images passent par `ExerciseMedia` (7.4). Retirer ou remplacer les photos ne doit jamais demander de toucher aux écrans.
6. **Pas d'extrapolation** : n'embarquer que les 15 exercices du tableau 7.3. Pour un futur exercice, une correspondance **vérifiée visuellement par un humain** est nécessaire ; l'IA n'en invente pas.
7. **Attribution** : non exigée par la licence. Ajouter tout de même, par courtoisie, une ligne discrète dans l'écran de profil ou de paramètres : « Photos d'exercices : free-exercise-db (domaine public) ». Ne pas bloquer la livraison si l'écran n'existe pas.

### 7.3 Correspondance FitTrack → free-exercise-db (vérifiée : les 30 fichiers existent)

URL de base : `https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/<dossier>/<0|1>.jpg`

| Id FitTrack | Exercice FitTrack | Dossier free-exercise-db | Remarque |
|---|---|---|---|
| `pec-001` | Développé couché barre | `Barbell_Bench_Press_-_Medium_Grip` | |
| `pec-002` | Pompes | `Pushups` | |
| `pec-003` | Écarté couché haltères | `Dumbbell_Flyes` | |
| `dos-001` | Tractions | `Pullups` | |
| `dos-002` | Rowing barre | `Bent_Over_Barbell_Row` | |
| `dos-003` | Tirage vertical poulie | `Wide-Grip_Lat_Pulldown` | prise large : approximation la plus proche, aucune entrée « Lat Pulldown » générique |
| `jam-001` | Squat | `Barbell_Squat` | |
| `jam-002` | Fentes | `Dumbbell_Lunges` | variante haltères |
| `jam-003` | Presse à cuisses | `Leg_Press` | |
| `epa-001` | Développé militaire | `Standing_Military_Press` | |
| `epa-002` | Élévations latérales | `Side_Lateral_Raise` | |
| `bra-001` | Curl biceps haltères | `Dumbbell_Bicep_Curl` | |
| `bra-002` | Extension triceps poulie | `Triceps_Pushdown` | |
| `abd-001` | Crunch | `Crunches` | |
| `abd-002` | Gainage planche | `Plank` | |

L'IA doit **ouvrir chaque paire de photos et confirmer qu'elle correspond bien à l'exercice** ; en cas de doute, elle le signale au lieu de choisir à la place du propriétaire.

### 7.4 Fichiers à créer ou modifier

**Piège Flutter** : la déclaration d'un dossier d'assets dans `pubspec.yaml` n'est **pas récursive**. On aplatit donc les fichiers et on les nomme avec l'id FitTrack.

| Fichier | Rôle |
|---|---|
| `fittrack_mobile_flutter/assets/exercises/<id>_0.jpg`, `<id>_1.jpg` | 30 photos renommées (ex. `pec-001_0.jpg`) |
| `fittrack_mobile_flutter/assets/exercises/NOTICE.md` | Traçabilité (7.2, règle 3) |
| `fittrack_mobile_flutter/scripts/fetch_exercise_media.sh` | Script reproductible de téléchargement et de renommage (`curl -fsSL`, arrêt à la première erreur) |
| `fittrack_mobile_flutter/pubspec.yaml` | Ajouter sous `flutter:` → `assets:` la ligne `- assets/exercises/` (aucune dépendance) |
| `lib/features/exercises/domain/exercise_media.dart` | Résolution des chemins d'images (fonctions pures) |
| `lib/shared/widgets/exercise_media_widgets.dart` | `ExerciseThumb` et `ExerciseDemo` |
| `test/exercise_media_test.dart` | Tests |

API attendue de `ExerciseMedia` :

```dart
class ExerciseMedia {
  static const String basePath = 'assets/exercises';
  /// Ids FitTrack pour lesquels des photos sont embarquées (les 15 du tableau 7.3).
  static const Set<String> availableIds = { 'pec-001', /* ... */ };
  /// ['assets/exercises/pec-001_0.jpg', 'assets/exercises/pec-001_1.jpg'] ou [] si inconnu / vide.
  static List<String> pathsFor(String exerciseId);
  /// Résout un id OU un uuid vers l'id canonique, via la liste d'exercices ; null si introuvable.
  static String? canonicalId(String idOrUuid, Iterable<ExerciceModel> exercises);
}
```

`canonicalId` est indispensable : `ExerciceSeanceModel.exerciceId` peut contenir l'`id` **ou** l'`uuid` (voir section 2).

### 7.5 Widgets (aucune dépendance nouvelle)

- **`ExerciseThumb({required String exerciseId, double size = 48})`** : miniature carrée aux coins arrondis, première photo (`_0`). Sans photo disponible, ou si le fichier est introuvable (`errorBuilder`) : fond `AppColors.surface1` avec l'icône `Icons.fitness_center` en `AppColors.textMuted`. Ne jamais lever d'exception ni afficher d'erreur à l'écran.
- **`ExerciseDemo({required String exerciseId, double height = 160})`** : alterne les deux photos toutes les ~900 ms avec un `AnimatedSwitcher` (fondu ~300 ms, `gaplessPlayback: true`). Le `Timer.periodic` est annulé dans `dispose`. Si `MediaQuery.of(context).disableAnimations` est vrai, ou s'il n'y a qu'une photo, afficher l'image fixe.
- Respecter le thème existant (`core/theme/app_theme.dart`).

### 7.6 Où les afficher (diff minimal)

1. **`exercises_page.dart`** : `ExerciseThumb` en tête de chaque ligne d'exercice.
2. **`_AddExerciseDialog`** (dans `workout_page.dart`) : un `ExerciseDemo` sous le menu déroulant, avec `key: ValueKey(_selectedId)` pour qu'il se mette à jour au changement d'exercice. Si le livrable (a) est déjà appliqué, le placer au-dessus de la ligne « Dernière séance… ».
3. **`workout_page.dart`**, en-tête de chaque exercice de la séance : un `ExerciseThumb` de 44 px, avec l'id résolu par `ExerciseMedia.canonicalId(exerciceId, tousLesExercices)`.

Aucune autre refactorisation du fichier. La logique reste dans `ExerciseMedia` et dans les widgets partagés.

### 7.7 Tests

- Chaque id de `availableIds` retourne **exactement 2 chemins**, et chaque fichier correspondant **existe sur disque** (`File(path).existsSync()`, les tests s'exécutent depuis la racine du package).
- `pathsFor('')` et `pathsFor('inconnu')` retournent `[]`.
- `canonicalId` résout un `id`, résout un `uuid`, et retourne `null` pour une valeur inconnue ou vide.
- `pubspec.yaml` contient bien la ligne `assets/exercises/` (lecture du fichier dans le test).
- Test de widget : `ExerciseThumb` avec un id inconnu affiche l'icône de remplacement ; avec un id connu, il affiche un widget `Image`.

## 8. Contraintes générales

- **Lire avant d'écrire** : ouvrir `models.dart`, `app_providers.dart`, `workout_page.dart`, `charts.dart`, `pubspec.yaml` et les routes backend ; ne pas inventer de noms de fichiers ou d'API.
- **Diff minimal et réversible** : pas de renommage, pas de reformatage global, pas de nouvelle dépendance dans `pubspec.yaml` (déclarer le dossier d'assets est autorisé).
- **Secrets** : ne pas lire à voix haute, afficher ni recopier le contenu de `fittrack-backend/.env`.
- **Qualité** : le code doit passer `flutter analyze` sans nouvelle alerte et les nouveaux tests doivent passer avec `flutter test`. Si l'IA ne peut pas exécuter ces commandes, elle doit le **dire explicitement** au lieu d'affirmer que tout fonctionne.
- **Langue** : documentation et messages en français ; identifiants de code en anglais pour les nouveaux fichiers.

## 9. Critères d'acceptation

**(a)**
- [ ] `flutter test` passe, avec les vecteurs de la section 5.2.
- [ ] Charger un jour de programme reprend les séries de la dernière séance validée ; sans historique, on retrouve 3 × 10 × 0 kg.
- [ ] Dans « Ajouter un exercice », changer d'exercice met à jour répétitions, charge et la ligne « Dernière séance… ».
- [ ] Un échec de chargement de l'historique ne bloque rien.
- [ ] Aucune modification de `_numberOfSets`, aucune nouvelle dépendance.
- [ ] Aucun code copié d'openGym.

**(b)**
- [ ] `CLAUDE.md` à la racine, avec les 10 sections, chaque affirmation vérifiable dans le dépôt.
- [ ] Aucune valeur secrète dans le fichier.

**(c)**
- [ ] 30 photos dans `assets/exercises/` (deux par exercice, nommées `<id>_0.jpg` / `<id>_1.jpg`), toutes issues de free-exercise-db et copiées sans modification.
- [ ] `NOTICE.md` complet : source, SHA amont, date, licence, tableau de correspondance, mention de la provenance non auditée.
- [ ] Chaque correspondance du tableau 7.3 a été contrôlée visuellement ; les doutes sont signalés.
- [ ] Les images s'affichent dans la liste des exercices, la boîte « Ajouter un exercice » et l'écran de séance ; sans photo, l'icône de remplacement apparaît sans erreur.
- [ ] `flutter test` passe, aucune nouvelle dépendance, aucune image provenant d'une autre source (openGym compris).

## 10. Format de la réponse attendue

1. La liste des fichiers créés ou modifiés, avec un court résumé de chacun.
2. Le résultat de `flutter analyze` et `flutter test` (ou la mention claire qu'ils n'ont pas pu être exécutés).
3. Le contenu complet de `CLAUDE.md`.
4. Pour (c) : le tableau de correspondance final, les éventuels doutes sur une paire de photos, et le SHA amont utilisé.
5. Les points qui restent à valider à la main (comportement à l'écran, cas limites).

## 11. Hors périmètre (à ne pas faire dans cette passe)

- Courbe 1RM dans `ChargeEvolutionGraphWidget`.
- Persistance d'un état « série faite » ou nettoyage des séries non cochées à la validation.
- Détection des PR, règles de progression, récupération musculaire.
- Découpage de `workout_page.dart`, offline-first.
- Images : GIF ou vidéos, photos pour d'autres exercices que les 15 listés, source wger, hébergement des images sur un CDN.
- Purge de l'historique Git ou rotation des secrets (à traiter à part par le propriétaire du dépôt).

> ⚠️ **À faire par le propriétaire avant de confier le dépôt à une IA** : `fittrack-backend/.env` contient une `MONGO_URI` Atlas et un `JWT_SECRET` faible. Changer le mot de passe MongoDB, régénérer un `JWT_SECRET` long et aléatoire, ajouter un `.gitignore` racine et retirer ces fichiers de l'index (`git rm -r --cached`).
