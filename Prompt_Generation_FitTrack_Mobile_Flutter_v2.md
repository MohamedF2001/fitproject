Tu es un développeur Flutter senior spécialisé dans la conception d'applications mobiles modernes, maintenables et production-ready.

Ta mission est de concevoir et générer l'application Flutter complète décrite ci-dessous.

> ⚠️ Ce prompt remplace une version précédente qui supposait un backend plus riche
> (recommandations IA, records, statistiques, abonnement, synchronisation offline
> avancée). Le backend **FitTrack API réellement construit** est plus simple : il
> ne couvre que Auth, Exercices (catalogue statique), Programmes, Séances,
> Objectifs et Succès. Toutes les sections ci-dessous sont alignées strictement
> sur ce backend réel — n'ajoute aucune fonctionnalité, endpoint ou champ qui n'y
> existe pas.

---

## 🎯 PROJET

**Nom du projet :** FitTrack Mobile

**Description :** Application mobile compagnon de l'API **FitTrack** (Node.js/Express/MongoDB), une plateforme de suivi fitness. L'application permet à l'utilisateur de créer son profil, gérer ses programmes d'entraînement (jours/horaires/exercices), démarrer des séances et enregistrer ses séries (répétitions, charge, repos), suivre ses objectifs, et débloquer des succès générés automatiquement par le backend après chaque séance validée ou mise à jour de poids.

**Public cible :** Pratiquants de fitness/musculation (débutant à avancé), en salle ou à domicile, marché francophone d'Afrique de l'Ouest.

**Plateformes :** Android, iOS. Web non prioritaire en V1 (architecture compatible pour extension future).

---

## 🧱 STACK TECHNIQUE OBLIGATOIRE

- Flutter / Dart, Material 3
- Clean Architecture
- Riverpod (`Notifier`/`AsyncNotifier`) pour la gestion d'état — **pas de Bloc/Cubit**
- GoRouter pour la navigation
- Dio + Retrofit pour les appels HTTP vers FitTrack API
- Freezed + `freezed_annotation` pour les modèles immuables et unions d'état
- `json_serializable` pour la sérialisation JSON
- Hive pour le cache local (catalogue d'exercices, session, dernier programme actif) — voir section Stockage local pour le périmètre exact (pas de moteur de synchronisation offline générique : le backend n'expose aucun endpoint `/sync`)
- Firebase : non utilisé
- `.env` pour `API_BASE_URL`
- Architecture modulaire et scalable

Évite les dépendances inutiles.

---

## 🏗️ ARCHITECTURE

```
lib/
├── core/
│   ├── constants/         # endpoints, clés Hive, enums (jours, statuts, types d'objectif)
│   ├── errors/             # Failure (Freezed union)
│   ├── network/            # DioClient, AuthInterceptor, ErrorInterceptor
│   ├── router/             # GoRouter + guards (auth, profil complet, programme actif)
│   ├── storage/            # Hive boxes, stockage sécurisé du token
│   ├── theme/              # Design system FitTrack "Kinetic Volt" (voir section UI/UX)
│   ├── utils/              # calcul IMC, formatters date/durée
│   └── widgets/            # AppButton, AppTextField, AppCard, AppLoader, AppError, EmptyState...
├── features/
│   ├── auth/               # register, login, profil (auth/profile)
│   ├── exercises/          # catalogue d'exercices (lecture seule, public)
│   ├── programs/           # programmes, jours, exercices de programme
│   ├── workouts/           # séances (brouillon → validée), séries, timer de repos
│   ├── goals/              # objectifs (4 types réels) + questions de motivation
│   ├── achievements/       # succès débloqués
│   └── settings/           # profil, préférences locales, déconnexion
├── shared/
│   ├── widgets/
│   ├── extensions/
│   └── helpers/
└── main.dart
```

Chaque `feature/` suit :
```
feature/
├── data/
│   ├── datasources/        # remote (Retrofit) + local (Hive) si pertinent
│   ├── models/              # Freezed + json_serializable (miroir des schémas Mongoose réels)
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/         # interfaces abstraites
│   └── usecases/
└── presentation/
    ├── providers/
    ├── pages/
    ├── widgets/
    └── controllers/           # ex : WorkoutSessionController (timer de repos)
```

Ne crée pas une architecture artificiellement complexe pour une fonctionnalité simple (`achievements` peut n'avoir qu'un repository + une page de liste + un écran de célébration, sans use cases surnuméraires).

---

## 🌐 API & BACKEND

L'application communique avec **FitTrack API** (backend déjà généré, documenté via `swagger.json` sur `/api-docs`). Base URL : `{{API_BASE_URL}}/api`.

⚠️ Important — **le backend ne renvoie PAS d'enveloppe générique `{ success, data, pagination }`**. Chaque endpoint a sa propre forme de réponse, en français, illustrée ci-dessous. Modélise les réponses exactement comme documenté, sans inventer de champ.

Centralise la configuration réseau :
- `DioClient` : base URL lue depuis `.env`, timeouts configurés
- `AuthInterceptor` : ajoute `Authorization: Bearer <token>` (token lu depuis le stockage sécurisé/Hive)
- Intercepteur d'erreurs : transforme les réponses d'erreur (`{ message, error? }`) en `Failure` exploitables par la Presentation
- Gestion du `401` : déconnexion automatique + redirection vers `/login` (**pas de refresh token en V1** — le backend n'en fournit pas ; prévoir une abstraction `AuthRepository.refreshToken()` qui lève une `UnimplementedFailure` proprement pour brancher un vrai refresh plus tard)
- Un `ApiService` Retrofit par feature : `AuthApiService`, `ExercicesApiService`, `ProgrammesApiService`, `SeancesApiService`, `ObjectifsApiService`, `SuccesApiService`

Flux d'appel :
```
Presentation → Provider/Controller → UseCase → Repository → DataSource/ApiService → FitTrack API
```

Les modèles API (JSON brut) ne sont pas utilisés directement comme entités `domain` : chaque repository convertit `Model → Entity` (et `Entity → Model` pour les créations/mises à jour).

---

## 📦 MODÈLES

Utilise Freezed pour tous les modèles, en miroir exact des schémas Mongoose réels du backend (champs en français, tels quels).

```dart
@freezed
class SeanceModel with _$SeanceModel {
  const factory SeanceModel({
    required String id,
    required DateTime date,
    required List<ExerciceSeanceModel> exercices,
    @Default('brouillon') String statut, // brouillon | validee
    DateTime? valideeLe,
  }) = _SeanceModel;

  factory SeanceModel.fromJson(Map<String, dynamic> json) => _$SeanceModelFromJson(json);
}
```

Modèles à prévoir (un par ressource réelle) :
- `UserModel` (`_id`, `email`, `nom`, `prenom`, `poids`, `taille`)
- `GroupeExerciceModel` (`muscle`, `exercices: List<ExerciceModel>`), `ExerciceModel` (`id`, `uuid`, `name_fr`, `description_fr`, `category`, `muscles_primary`, `muscles_secondary`, `equipment`)
- `ProgrammeModel` (`_id`, `utilisateur`, `nom`, `jours: List<JourModel>`, `actif`, `dateCreation`)
- `JourModel` (`jour` enum Lundi..Dimanche, `horaire` String type "07:00", `exercices: List<ExerciceProgrammeModel>`)
- `ExerciceProgrammeModel` (`exerciceId`, `ordre`)
- `SeanceModel`, `ExerciceSeanceModel` (`exerciceId`, `series: List<SerieModel>`, `tempsRepos`), `SerieModel` (`numero`, `repetitions`, `charge`)
- `ObjectifModel` (`_id`, `utilisateur`, `type` enum, `valeurCible`, `questionsMotivation: List<QuestionMotivationModel>`, `statut` enum, `dateCreation`, `dateCible`)
- `QuestionMotivationModel` (`question`, `reponse`)
- `SuccesModel` (`_id`, `utilisateur`, `objectif`, `dateObtention`, `description`)
- `AuthResponseModel` (`message`, `token`, `user: UserModel`)

Prévois systématiquement `fromJson`/`toJson`, conversion `Model → Entity`, et des payloads dédiés pour les créations (`CreateProgrammeInput`, `CreateSeanceInput`, `AjouterSerieInput`, `CreateObjectifInput`, etc.), sans champ absent du backend (ex : **pas de RPE, pas de 1RM, pas de champ `niveau`/`fréquence` sur le profil** — voir section Écrans pour le détail des divergences avec la maquette Stitch).

---

## 🔐 AUTHENTIFICATION

JWT via `POST /api/auth/register` et `POST /api/auth/login` — **email + mot de passe uniquement** (pas de nom/prénom à l'inscription, pas de connexion Google/Apple : le backend ne le supporte pas, même si la maquette Stitch en affiche — ces boutons ne doivent pas être câblés, ou doivent être retirés de l'écran généré).

Implémente :
- Login, Register, Logout
- Persistance de session (token + utilisateur en Hive/stockage sécurisé, restaurés au démarrage)
- Protection des routes via `redirect` GoRouter

Logique post-authentification :
1. Après login/register réussi, stocker le token, appeler `GET /api/auth/profile`.
2. Si `nom`, `prenom`, `poids` ou `taille` sont `null` → redirection vers `/complete-profile` (écran "Compléter mon profil", `PUT /api/auth/profile`). Champs à collecter : **uniquement nom, prénom, poids (kg), taille (m ou cm selon convention choisie et documentée)**. Ne pas ajouter de champ "niveau" ou "fréquence d'entraînement/semaine" : absents du schéma `User`, purement décoratifs dans la maquette.
3. Profil complet → appelle `GET /api/programmes` :
   - Aucun programme → `/home` affiche un `EmptyState` ("Aucun programme actif" + CTA "Créer mon programme" vers `/programs/create`), sans bloquer la navigation vers les autres onglets.
   - Au moins un programme → `GET /api/programmes/actif` alimente `/home`.
4. Ces vérifications (`hasCompleteProfileProvider`, `hasActiveProgramProvider`) sont des providers Riverpod dédiés, consultés à la fois par le `redirect` GoRouter et par l'écran Home.

---

## 🧭 NAVIGATION

- **Routes publiques :** `/splash`, `/login`, `/register`
- **Route intermédiaire protégée hors-shell :** `/complete-profile`
- **Routes protégées (shell, bottom navigation 5 onglets) :** `/home`, `/programs`, `/workouts`, `/goals`, `/profile`
- **Routes secondaires (push) :** `/programs/create` (wizard, `programId` optionnel pour l'édition), `/programs/:id`, `/exercises` (catalogue, accessible aussi hors connexion via cache), `/exercises/:id`, `/workouts/:id` (séance active ou détail figé), `/goals/:id`, `/goals/create`, `/achievements`, `/achievements/celebrate` (paramètre `succesId`)
- **Navigation imbriquée :** `StatefulShellRoute` pour la bottom navigation, `Navigator` indépendant par onglet

Centralise toute la navigation dans `core/router/app_router.dart`.

---

## 🎨 UI / UX — DESIGN SYSTEM "KINETIC VOLT"

Reproduis fidèlement le design system fourni (issu de Google Stitch), sans le réinventer. Matérialise-le dans `core/theme/` sous forme de tokens Dart typés (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`), puis un `ThemeData` Material 3 `dark` (thème unique en V1, pas de variante claire).

**Brand :** interface technique et sobre pour salle de sport sombre, rejette les clichés motivationnels et les photos de stock — line-art épais, typographie géométrique, forte lisibilité des chiffres de performance pendant l'effort.

**Couleurs** (`AppColors`) :
| Rôle | Hex |
|---|---|
| Primary — Electric Volt (CTA, état actif, anneaux de progression) | `#CCFF00` |
| On Primary (texte/icône sur fond primary) | `#121417` |
| Secondary — Cyan Ice (biométrie, PR, timer de repos) | `#38BDF8` |
| Tertiary — Muted Slate (métadonnées, états inactifs) | `#94A3B8` |
| Canvas de base | `#121417` |
| Surface niveau 1 (groupes secondaires) | `#181B20` |
| Surface niveau 2 (cards, modules interactifs) | `#22272E` |
| Surface niveau 3 (modales, overlays, inputs actifs) | `#2B313A` |
| Texte principal — Off-White | `#F8FAFC` |
| Texte secondaire — Slate | `#8E9AA8` |
| Erreur | `#FFB4AB` sur `#93000A` |

Bordures fines : `1px solid rgba(255,255,255,0.08)` (cards), `0.12` (modales), `0.15` (bouton secondaire), `0.06` (barre de nav). Ombres : néant sur surfaces standards (`0px 10px 30px rgba(0,0,0,0.45)` très diffuse si besoin), glow primaire `0px 8px 24px rgba(204,255,0,0.22)`, glow FAB `0px 6px 20px rgba(204,255,0,0.35)`.

**Typographie** (`AppTypography`, police **Plus Jakarta Sans**) :
| Style | Taille/Line-height | Poids | Tracking |
|---|---|---|---|
| `metricDisplay` (chiffres clés : charge, temps, poids) | 48/52 (mobile compact : 40/44) | 800 | -0.03em |
| `headlineXl` | 32/38 | 700 | -0.02em |
| `headlineLg` | 24/30 | 700 | -0.01em |
| `headlineMd` | 20/26 | 600 | 0 |
| `bodyLg` | 16/24 | 400 | 0 |
| `bodyMd` | 14/20 | 400 | 0.01em |
| `labelLg` | 14/18 | 600 | 0.02em |
| `labelMd` | 12/16 | 600 | 0.04em |
| `labelMonoStat` (badges/unités KG·REPS·SEC, tout en majuscules) | 11/14 | 700 | 0.08em |

**Radius** (`AppRadius`) : sm 4, default 8, md 12, lg 16, xl 24, full 9999 (pill). Cards : 18–20px. Boutons/badges d'action : pill. Chips/steppers : 10–12px.

**Spacing** (`AppSpacing`) : gutter 16, margin écran 20 (compact : 16), xs 4, sm 8, md 16, lg 24, xl 32. Zones tactiles minimum 48×48px (steppers de série, contrôles de timer) pour rester utilisable en salle, en pleine série.

**Composants clés à reproduire** :
- `AppButton` primary (fond `#CCFF00`, texte `#121417`, 52px, pill, scale 0.98 au press), secondary (fond `#22272E`, bordure 0.15, texte off-white), ghost (transparent, texte slate)
- `AppCard` (`#22272E`, radius 18, bordure 0.08)
- `SetCompletionToggle` : disque 32px, incomplet = anneau slate 2px, complet = rempli `#CCFF00` avec check `#121417`
- `SetInputRow` : champs numériques encastrés (`#181B20`, radius 12, chiffres 24px bold off-white), steppers +/- 44px min
- `RestTimerWidget` : décompte local (pas d'appel API), pause/reprise, ajustement ±15s
- `StatusChip` (28px, radius 8, fond `rgba(255,255,255,0.05)`, texte `labelMonoStat` majuscule)
- Bottom navigation : fond `rgba(18,20,23,0.88)` + blur 16, bordure haute 0.06, icônes line-art 2px (slate/actif volt), 5 onglets **Accueil / Programmes / Séance / Objectifs / Profil** avec **FAB central Séance** (56px, fond `#CCFF00`, icône `#121417`, glow volt)

---

## 📱 RESPONSIVE

Fonctionne sur petits smartphones, smartphones standards, tablettes (layout verrouillé à 540px de large centré au-delà de 480px). Utilise `LayoutBuilder`, pas de duplication d'interface.

---

## 🔁 GESTION D'ÉTAT

Riverpod, providers organisés par feature. Union Freezed `ViewState<T>` (`initial`, `loading`, `success`, `empty`, `error`) pour tous les écrans à chargement de données. `WorkoutSessionNotifier` (Riverpod `Notifier`) pour le chrono de séance + le timer de repos, purement local.

---

## 💾 STOCKAGE LOCAL

⚠️ Le backend FitTrack **n'expose aucun endpoint de synchronisation** (`/sync`). N'implémente donc pas de moteur de synchronisation offline générique, de `clientId`, ni de file d'attente de résolution de conflits. Le périmètre Hive réel est :
- **Cache de lecture** : catalogue d'exercices (rafraîchi au démarrage, consultable hors-ligne), dernier programme actif connu, dernier profil connu — pour un affichage instantané, en lecture seule si hors-ligne
- **Session locale** : token JWT, utilisateur courant
- **Préférences locales** : unités d'affichage (kg/cm), rappels de séance (notifications locales)
- **Historique de poids local (optionnel, non synchronisé)** : à chaque mise à jour du poids via `PUT /api/auth/profile`, ajoute une entrée `{ date, poids }` dans une box Hive locale, pour tracer une courbe simple sur l'écran Profil. **Ce n'est pas une donnée serveur** : elle est perdue en cas de réinstallation/changement d'appareil ; documente cette limite dans le code et dans l'UI ("historique local à cet appareil").

Les écritures (créer une séance, ajouter une série, valider) appellent directement l'API : pas de mode d'édition hors-ligne en V1. Si la requête échoue faute de réseau, affiche une erreur claire et propose de réessayer (pas de file d'attente).

---

## ⚠️ GESTION DES ERREURS

`Failure` (union Freezed : `NetworkFailure`, `ServerFailure`, `ValidationFailure`, `AuthFailure`, `NotFoundFailure`, `UnknownFailure`), interceptée dans `core/network/`, jamais de `try/catch` dispersé dans les widgets (chaque repository retourne un `Either<Failure, T>` ou équivalent).

Cas spécifiques au backend réel : séance déjà validée (`403` sur `PUT /seances/:id`, `409` sur `PUT /seances/:id/valider`) → message explicite, pas de retry ; email déjà utilisé (`409` sur register) ; identifiants invalides (`401` sur login).

---

## 🧩 COMPOSANTS RÉUTILISABLES

`AppButton`, `AppTextField`, `AppCard`, `AppLoader`, `AppError`, `EmptyState`, `AppDialog`, `AppBottomSheet`, `RestTimerWidget`, `SetInputRow`, `SetCompletionToggle`, `StatusChip`, `ExercicePickerSheet` (bottom sheet de sélection d'exercice depuis le catalogue, recherche + filtre muscle/catégorie, réutilisé dans le wizard de programme et en séance libre), `ProgressBarObjectif` (comparaison valeur actuelle/cible).

Ne crée pas un composant pour chaque petit `Container`.

---

## ✅ QUALITÉ DU CODE

SOLID, DRY, séparation des responsabilités, null safety, conventions Dart/Flutter, noms explicites. Évite code mort, duplication, logique métier dans les widgets, constantes hardcodées (centralise dans `core/constants/`).

---

## ⚙️ CONFIGURATION

`.env` (non commité) + `.env.example` :
```
API_BASE_URL=http://localhost:3000/api
APP_ENV=development
```
Émulateur Android vers backend local : `http://10.0.2.2:3000/api`.

`.gitignore` Flutter standard + `.env`, `/build`, `.dart_tool/` (préciser le choix de versionner ou non les `*.g.dart`/`*.freezed.dart`).

---

## 📋 FONCTIONNALITÉS

### 1. Authentification & Profil
Inscription (email + mot de passe), connexion, complétion du profil (nom, prénom, poids, taille) au premier login, édition ultérieure. IMC calculé **localement** à partir de poids/taille (aucun endpoint IMC côté backend).

### 2. Catalogue d'exercices
Parcourir/filtrer le catalogue statique (`GET /api/exercices`, filtres `?muscle=`/`?categorie=`), fiche détail (`GET /api/exercices/:id`). Accessible sans connexion (public) et mis en cache pour consultation hors-ligne.

### 3. Programmes d'entraînement
CRUD complet, jours de la semaine (Lundi..Dimanche) avec horaire et exercices ordonnés (choisis dans le catalogue via `ExercicePickerSheet`). Un seul programme `actif` à la fois — bascule gérée côté backend (désactivation automatique des autres) au `save()`.

### 4. Séances
Créer une séance (liée ou non à un programme), l'enregistrer en brouillon, ajouter/modifier des séries (répétitions, charge, temps de repos) tant qu'elle est en brouillon, puis la **valider** via `PUT /seances/:id/valider` (figée ensuite, `403` sur toute tentative de modification ultérieure). La validation déclenche côté backend la vérification des objectifs et peut renvoyer des succès nouvellement débloqués (`succesObtenus` dans la réponse) : l'app doit les afficher immédiatement (écran de célébration).

### 5. Objectifs
Les **4 types réels supportés par le backend** — ne pas en inventer d'autres (pas de "1RM", pas d'objectif par exercice précis) :
- `perte_de_poids`
- `prise_de_muscle`
- `regularite_seances` (comparé au nombre de séances validées sur 7 jours glissants)
- `poids_cible` (comparé au poids courant du profil)

Création avec les 2 questions de motivation fixes ("Pourquoi cet objectif est important pour toi ?", "Combien de temps par semaine peux-tu y consacrer ?"), stockées telles quelles (pas de scoring). Liste avec comparaison condensée actuel/cible quand calculable (`poids_cible`, `regularite_seances`) ; pour `perte_de_poids`/`prise_de_muscle` (sans logique de vérification automatique côté backend), afficher un simple statut sans barre de progression chiffrée invented.

### 6. Succès
Liste des succès débloqués (`GET /api/users/succes`), écran de célébration après validation d'une séance ou mise à jour de poids ayant débloqué un ou plusieurs succès. La `description` affichée est **celle générée par le backend** (ex. "Objectif poids atteint : 75kg") — ne pas la remplacer par des noms de badges inventés ("Guerrier régulier", "Club des 100kg" de la maquette sont décoratifs, à remplacer par la vraie description backend, éventuellement accompagnée d'une icône générique selon le type d'objectif source).

Ajoute une fonctionnalité supplémentaire uniquement si elle reste lisible depuis les endpoints existants ; n'invente aucun nouvel endpoint.

---

## 🔄 FLUX UTILISATEUR CRITIQUES

### 1. Post-authentification → Profil → Programme actif
Voir section Authentification. Ordre strict : token → profil complet ? → programme actif ?

### 2. Création de programme (wizard, `/programs/create`)
1. **Infos** — nom du programme.
2. **Jours** — sélection des jours (Lundi..Dimanche), horaire par jour.
3. **Exercices par jour** — pour chaque jour, ajout d'exercices depuis le catalogue (`ExercicePickerSheet`) avec un simple ordre (`ordre` entier) — **pas de séries/répétitions cibles au niveau du programme** : ces valeurs ne sont saisies qu'au moment de la séance réelle (le schéma `Programme.jours[].exercices` ne contient que `exerciceId` et `ordre`).
4. Récapitulatif, option "Définir comme actif" (`actif: true` à l'enregistrement, `POST /api/programmes`).
5. Même écran réutilisé en édition (`PUT /api/programmes/:id`).

### 3. Séance active
1. `POST /api/seances` crée la séance en `brouillon` (date, exercices vides ou pré-remplis depuis le programme du jour). Chrono de séance local démarre (affichage uniquement, pas de champ `duree` côté backend à envoyer).
2. Onglets horizontaux par exercice (issus du programme du jour, ou ajoutés librement via `ExercicePickerSheet`).
3. Pour l'exercice actif : tableau de séries (numéro, répétitions, charge éditables via steppers), bouton "Ajouter une série". Chaque modification met à jour la séance via `PUT /seances/:id` (tant qu'elle est en brouillon).
4. Après chaque série, `RestTimerWidget` démarre un décompte purement local, pré-rempli avec le `tempsRepos` défini sur l'exercice, ajustable ±15s.
5. **Pas de bandeau de recommandation IA, pas de champ RPE à saisir ou envoyer** : ces éléments visibles sur la maquette Stitch n'ont pas de contrepartie backend.
6. Bouton "Terminer la séance" → `PUT /api/seances/:id/valider`. Affiche le résultat (séance figée) et, si `succesObtenus` non vide, enchaîne sur l'écran de célébration.

### 4. Objectifs — création et suivi
1. Création (`POST /api/users/objectifs`) : type, valeur cible (si pertinente selon le type), échéance, réponses aux 2 questions de motivation.
2. Détail (`GET /api/users/objectifs/:id`) : pour `poids_cible`, comparer au poids courant du profil (`GET /api/auth/profile`) ; pour `regularite_seances`, comparer au nombre de séances validées sur 7 jours (calcul client à partir de `GET /api/seances`, filtré `statut: validee` et `valideeLe` récent — le backend ne renvoie pas ce compteur pré-calculé).
3. Mise à jour manuelle du statut possible (`PUT /api/users/objectifs/:id`, ex. passage à `abandonne`).

---

## 🖥️ ÉCRANS

Correspondance directe avec la maquette Stitch fournie ("Kinetic Volt"), avec les ajustements de contenu ci-dessus :

1. **Splash** — vérifie la session en cache, redirige vers `/home`, `/complete-profile` ou `/login`
2. **Connexion / Inscription** — email + mot de passe uniquement. Retirer les boutons Google/Apple de la maquette (non supportés par le backend) ou les afficher désactivés avec une info-bulle "Bientôt disponible"
3. **Compléter mon profil** — nom, prénom, poids (kg), taille (cm) uniquement. Retirer les champs "Niveau" et "Fréquence d'entraînement/semaine" de la maquette (absents du schéma `User`)
4. **Accueil** — programme actif du jour (ou `EmptyState` + CTA si aucun), dernière séance, objectifs en cours (comparaison condensée), CTA "Créer une séance rapide sans programme"
5. **Mes Programmes** (liste + détail) — badge "Programme Actif"/"Inactif", planning hebdomadaire par jour
6. **Création/édition de programme** (wizard) — voir Flux critiques point 2
7. **Catalogue d'exercices** — liste groupée par muscle, filtres muscle/catégorie, fiche détail
8. **Séance en cours** — chrono, onglets d'exercices, séries (steppers reps/charge), timer de repos local, bouton "Terminer la séance". **Sans** bandeau recommandation IA ni champ RPE
9. **Historique des séances** — liste des séances passées (`GET /api/seances`, triées par date), accès au détail figé d'une séance validée (écran non présent dans l'export Stitch fourni : à concevoir dans le même design system)
10. **Mes Objectifs** — liste (4 types réels uniquement), création, détail avec comparaison actuel/cible quand calculable
11. **Célébration Succès** — affichée juste après une validation de séance ayant débloqué un succès, texte = `description` réelle du backend
12. **Profil** — infos (nom, prénom, poids, taille), IMC calculé localement, historique de poids **local uniquement** (voir Stockage local), déconnexion, préférences (unités, rappels)

Écrans de la maquette Stitch **hors périmètre V1** (aucune contrepartie backend, à ne pas générer tels quels) :
- **Profil — Évolution** et **Profil — Évolution composition corporelle** (masse grasse/maigre/musculaire, eau corporelle) : le backend ne stocke qu'un poids courant, aucune composition corporelle
- **Profil — Évolution prédictive** ("IA Prédictive", trajectoire projetée) : aucun moteur de prédiction côté backend

Si tu veux conserver l'esprit visuel de ces écrans, limite-toi à un graphique simple de l'historique de poids **local** (point 12 ci-dessus), sans IMC "zone optimale" inventée ni projection IA.

---

## 🔗 API — ENDPOINTS RÉELS

Toutes les routes ci-dessous nécessitent `Authorization: Bearer <token>`, sauf mention "Public".

### Auth
```
POST /auth/register        Public   { email, motDePasse } → { message, token, user }
POST /auth/login           Public   { email, motDePasse } → { message, token, user }
GET  /auth/profile                  → user
PUT  /auth/profile                  { nom?, prenom?, poids?, taille? } → { message, user }
```

### Exercices
```
GET /exercices              Public   ?muscle= &categorie= → [ { muscle, exercices: [...] } ]
GET /exercices/:id          Public   → { muscle, id, uuid, name_fr, description_fr, category, muscles_primary, muscles_secondary, equipment }
```

### Programmes
```
POST   /programmes                  { nom, jours?, actif? } → { message, programme }
GET    /programmes                  → [ programme ]
GET    /programmes/actif            → programme | {}
GET    /programmes/:id              → programme
PUT    /programmes/:id              { nom?, jours?, actif? } → { message, programme }
DELETE /programmes/:id              → { message }
```

### Séances
```
POST   /seances                     { date?, exercices? } → { message, seance }
GET    /seances                     → [ seance ]
GET    /seances/:id                 → seance
PUT    /seances/:id                 { date?, exercices? } → { message, seance }  (403 si déjà validée)
DELETE /seances/:id                 → { message }
PUT    /seances/:id/valider         → { message, seance, succesObtenus: [succes] }  (409 si déjà validée)
```

### Objectifs
```
POST /users/objectifs                { type, valeurCible?, dateCible?, reponses? } → { message, objectif }
GET  /users/objectifs                → [ objectif ]
GET  /users/objectifs/:id            → objectif
PUT  /users/objectifs/:id            { valeurCible?, statut?, dateCible? } → { message, objectif }
```

### Succès
```
GET /users/succes                    → [ succes ]
```

Aucun autre endpoint n'existe (pas de `/records`, `/statistics`, `/recommendations`, `/subscription`, `/sync`). N'implémente ni `ApiService`, ni feature, ni écran correspondant.

---

## 🚀 LIVRABLE ATTENDU

Application Flutter complète, prête à ouvrir dans Android Studio/VS Code, connectée à FitTrack API :
1. `pubspec.yaml`
2. Structure complète des dossiers
3. `main.dart`, chargement `.env`
4. Thème "Kinetic Volt" (Material 3)
5. Routing GoRouter (shell + guards)
6. Modèles Freezed (un par ressource réelle)
7. Entités domain
8. Repositories (interfaces + implémentations)
9. Datasources (Retrofit + Hive)
10. Services API Retrofit (un par feature réelle)
11. Use cases
12. Providers Riverpod
13. Controllers (chrono de séance, timer de repos)
14. Pages (12 écrans listés, sans les 3 écrans hors périmètre)
15. Widgets réutilisables
16. Gestion des erreurs (Failure, interceptors)
17. Stockage local (Hive : cache + historique de poids local)
18. Authentification (JWT, persistance, guards)
19. `.env.example`, `.gitignore`

---

## 🧠 RÈGLE IMPORTANTE DE GÉNÉRATION

Avant d'écrire le code : identifie les entités à partir des schémas Mongoose réels ci-dessus (pas de la maquette Stitch), les relations (Programme → Jour → ExerciceProgramme → Exercice catalogue ; Seance → ExerciceSeance → Serie ; Objectif → Succes), l'architecture, les routes, les modèles, les repositories, les providers, les écrans — puis vérifie la cohérence globale (chaque import correspond à un fichier réel, chaque route est déclarée, chaque provider est défini, chaque modèle Freezed est valide pour `build_runner`).

Ensuite seulement, génère le code.

---

## 💻 COMMANDES

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

En parallèle, backend local : `npm start` (ou `npm run dev`) depuis le dossier du backend FitTrack API, avec `API_BASE_URL=http://10.0.2.2:3000/api` dans `.env` pour l'émulateur Android (ou l'IP LAN pour un appareil physique).

Précise les versions minimales compatibles Dart 3 pour `riverpod`, `go_router`, `retrofit_generator`, `freezed`, `hive`/`hive_ce`.

---

## ⚠️ IMPORTANT

Ne simplifie pas artificiellement le projet, mais ne rajoute rien qui ne soit pas dans le backend réel décrit ci-dessus. N'implémente jamais un champ, un endpoint ou un écran visible dans la maquette Stitch mais absent des schémas Mongoose et des routes listées en section API. En cas de doute entre "fidèle à la maquette visuelle" et "fidèle au backend réel", **le backend réel gagne toujours** — adapte le texte/les champs de l'écran, jamais l'inverse.

Si la réponse devient trop longue, continue en plusieurs parties en conservant exactement la même architecture et les mêmes conventions.
