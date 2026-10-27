# Fiche technique — FitTrack

> **État du dépôt au 25 octobre 2026**  
> Analyse statique des sources et configurations présentes à la racine de `FitProject`. Cette fiche décrit l’implémentation observée ; elle ne certifie ni l’exécution en production, ni la réussite des builds ou des tests.

## 1. Présentation

FitTrack est une application de suivi de musculation dont le dépôt réunit une application mobile Flutter, une API REST Node.js/Express et des maquettes de conception. L’application mobile communique avec l’API pour l’authentification, le catalogue d’exercices, les programmes, les séances, les objectifs et les succès. MongoDB est utilisé comme stockage serveur via Mongoose. Une partie de certaines données est mise en cache localement avec Hive.

Le répertoire `openGym/` est un projet tiers indépendant, sous licence AGPL-3.0, présent comme référence produit. Il ne fait pas partie de l’application FitTrack décrite ci-dessous et possède sa propre pile web et ses propres procédures d’installation.

## 2. Périmètre et structure du dépôt

| Chemin | Rôle |
|---|---|
| `fittrack_mobile_flutter/` | Application Flutter/Dart, interface, état applicatif, accès API et persistance locale. |
| `fittrack-backend/` | API REST Express, modèles Mongoose, contrôleurs, catalogue français et documentation Swagger. |
| `stitch_fittrack_mobile_app/` | Maquettes et exports visuels HTML/images pour les écrans FitTrack. |
| `openGym/` | Projet open source tiers utilisé comme source d’inspiration fonctionnelle ; licence AGPL-3.0. |
| `BRIEF_IA_FitTrack_openGym.md` | Brief de développement historique. À comparer aux sources actuelles, car certaines informations sont périmées. |
| `Prompt_Generation_FitTrack_Mobile_Flutter_v2.md`, `prompt_backend_fittrack2.md` | Prompts et spécifications historiques. |
| `CLAUDE.md` | Guide du dépôt, de son architecture, de ses conventions et de limites connues. |

## 3. Architecture générale

```text
Application Flutter
  UI Flutter → Riverpod → repositories / cas d’usage → datasources Dio/Retrofit
                                                           │ REST + JWT
                                                           ▼
API Node.js / Express → routes → middleware JWT → contrôleurs → modèles Mongoose
                                                           │
                                                           ▼
                                                    MongoDB (MONGO_URI)
```

L’API est configurée pour fonctionner comme serveur Node local et pour exporter l’application Express comme handler serverless Vercel. Le frontend utilise une URL configurable via `API_BASE_URL`, avec une URL Vercel de secours définie dans `lib/main.dart`.

### Application mobile

La structure actuelle est organisée par fonctionnalité, avec séparation des responsabilités :

- `lib/core/` : modèles partagés, constantes, erreurs, routage, thèmes, client HTTP, providers généraux et stockage Hive.
- `lib/features/auth/` : connexion, inscription, profil et état d’authentification.
- `lib/features/exercises/` : lecture du catalogue et résolution des médias d’exercice.
- `lib/features/programs/` : consultation, création et gestion des programmes.
- `lib/features/workouts/` : séances, historique, séance en cours et chronomètre de repos.
- `lib/features/goals/` : objectifs.
- `lib/features/achievements/` : succès obtenus.
- `lib/features/settings/` : profil et historique de poids local.
- `lib/features/onboarding/`, `lib/features/splash/` : parcours de démarrage.
- `lib/shared/` : shell d’application, graphiques, widgets d’images et aides transverses.

La navigation repose sur GoRouter. Riverpod fournit les services, repositories et fournisseurs de données. Dio assure les appels HTTP ; son intercepteur ajoute le bearer token conservé dans Hive. Des modèles de données et entités de domaine séparés sont convertis dans les repositories.

### Backend

Le backend utilise des modules ES Node.js :

- `server.js` initialise dotenv, Express et CORS, connecte MongoDB, charge le catalogue JSON en mémoire, monte les routes et expose Swagger sur `/api-docs`.
- `routes/` déclare les chemins HTTP et applique `verifyToken` aux routes privées.
- `controllers/` porte les opérations applicatives et l’accès aux modèles.
- `models/` définit les schémas Mongoose (`User`, `Programme`, `Seance`, `Objectif`, `Succes`).
- `middlewares/auth.js` vérifie les JWT et peuple `req.userId`.
- `utils/goalsChecker.js` évalue les objectifs et crée les succès associés.
- `data/exercises_by_muscle_fr.json` contient le catalogue regroupé par muscle.

## 4. Technologies et dépendances principales

| Composant | Technologies constatées |
|---|---|
| Mobile | Flutter, Dart `>=3.5.0 <4.0.0`, Riverpod 2, GoRouter 14, Dio 5, Retrofit 4, Hive, `flutter_dotenv`, `intl`, `video_player`. |
| Génération / qualité Dart | `build_runner`, `freezed`, `json_serializable`, `retrofit_generator`, `flutter_lints`. Les modèles centraux incluent toutefois des conversions JSON écrites à la main. |
| Backend | Node.js avec modules ES, Express 4, Mongoose 8, MongoDB, JWT (`jsonwebtoken`), bcryptjs, dotenv, Swagger UI. |
| Déploiement API | Configuration Vercel dans `fittrack-backend/vercel.json`. |
| Documentation API | OpenAPI 3 dans `fittrack-backend/swagger.json`. |

Les versions listées proviennent des manifests du dépôt et de leurs contraintes ; elles ne remplacent pas l’inventaire des versions réellement installées sur un environnement de production.

## 5. Fonctionnalités et règles métier observées

### Authentification et profil

- Inscription et connexion par email et mot de passe.
- Les mots de passe sont hachés avec bcryptjs (10 tours de sel) par le hook Mongoose `pre('save')`.
- L’API retourne un JWT signé avec `JWT_SECRET` et `JWT_EXPIRES_IN`.
- Les routes privées attendent `Authorization: Bearer <token>`.
- Le modèle utilisateur contient notamment email, nom, prénom, poids, taille et historique de poids. Le champ mot de passe est omis de la sérialisation JSON du modèle.
- Le profil et son historique de poids serveur sont modifiés par les routes de profil. L’application conserve aussi une série de poids locale Hive, qui n’est pas automatiquement synchronisée avec l’API selon le README mobile.

### Exercices

- Le catalogue est livré côté backend sous forme d’un JSON chargé au démarrage et exposé en lecture.
- Le modèle comprend identifiant, UUID, noms/descriptions français, catégorie, muscles et équipement.
- Les photos embarquées dans l’application couvrent 15 identifiants d’exercice, soit 30 fichiers JPG (deux par identifiant). Leur attribution est documentée dans `fittrack_mobile_flutter/assets/exercises/NOTICE.md`.
- `ExerciseMedia` sait résoudre un identifiant `id` ou `uuid` vers l’identifiant canonique et retourner les chemins des images correspondantes.

### Programmes

- Un programme contient un nom, des jours de la semaine, un horaire et une liste d’exercices ordonnés.
- Un seul programme actif par utilisateur est recherché ; le modèle désactive les autres programmes lors de l’enregistrement d’un programme actif.
- Les routes de création, lecture, modification et suppression sont authentifiées.

### Séances et séries

- Une séance contient un propriétaire, une date, des exercices et un statut `brouillon` ou `validee`.
- Une série contient `numero`, `repetitions` et `charge` ; une charge à zéro représente notamment du poids du corps ou une charge non renseignée. Le repos par exercice est de 60 secondes par défaut.
- La validation passe par `PUT /api/seances/:id/valider`, fixe `valideeLe`, bloque les validations répétées (409), puis déclenche la vérification des objectifs.
- La mise à jour d’une séance validée est interdite (403). La suppression reste possible via la route DELETE, même pour une séance validée : la validation ne la rend donc pas entièrement immuable.
- L’interface garde des coches de séries terminées dans l’état de la page ; aucun champ correspondant n’existe dans le schéma API/Mongoose. Ces coches ne sont pas persistées par le modèle serveur.
- L’historique d’entraînement est récupéré par API ; il n’existe pas de cache Hive équivalent dans les providers de séances.

### Estimation du 1RM et préremplissage

Ces fonctions sont déjà présentes, contrairement à ce que laisse entendre le brief historique :

- `lib/core/utils/one_rm.dart` implémente Epley, Brzycki et Lombardi ; Epley est la formule par défaut, le plafond est 12 répétitions et les résultats sont arrondis au dixième. Les entrées non exploitables renvoient `null`.
- `lib/features/workouts/domain/last_sets.dart` retrouve les séries de la séance validée la plus récente pour un exercice, accepte plusieurs identifiants, utilise `valideeLe` puis `date`, renumérote les séries et fournit résumé et série de tête.
- Des tests dédiés existent dans `test/one_rm_test.dart` et `test/last_sets_test.dart`.
- Les tests médias et un test widget sont également présents : `exercise_media_test.dart` et `widget_test.dart`.
- `shared/widgets/charts.dart` contient les graphiques de progression ; le guide du dépôt signale que le graphique d’évolution de charge montre la charge brute, sans courbe 1RM.

### Objectifs et succès

- Types d’objectifs gérés côté backend : poids cible, perte de poids, prise de muscle, régularité des séances et charge maximale.
- Les objectifs de régularité comptent les séances validées sur les sept derniers jours.
- La charge maximale est calculée à partir des charges des séries des séances validées. Il s’agit de la charge la plus haute enregistrée, pas d’un 1RM estimé, et le calcul s’effectue globalement pour l’utilisateur, pas par exercice.
- Un objectif atteint est marqué `atteint` et produit un document `Succes`.
- **Point à revoir :** dans `goalsChecker.js`, les règles `poids_cible` et `perte_de_poids` comparent toutes deux `user.poids <= valeurCible`. Vérifier si cela correspond aux règles métier voulues.

## 6. Contrat API résumé

Base de routes montée par le backend : `/api`. Les opérations métier renvoient principalement du JSON. Swagger est accessible à `/api-docs` sur le serveur.

| Préfixe | Routes observées | Authentification |
|---|---|---|
| `/api/auth` | `POST /register`, `POST /login`, `GET /profile`, `PUT /profile` | Inscription/connexion publiques ; profil privé. |
| `/api/exercices` | `GET /`, `GET /:id` | Routes publiques dans le montage actuel. |
| `/api/programmes` | `POST /`, `GET /`, `GET /actif`, `GET /:id`, `PUT /:id`, `DELETE /:id` | JWT requis. |
| `/api/programmes` | `POST /proposition` | JWT requis ; appelle Gemini et retourne une proposition non enregistrée. |
| `/api/seances` | `POST /`, `GET /`, `GET /:id`, `PUT /:id`, `DELETE /:id`, `PUT /:id/valider` | JWT requis. |
| `/api/users` | CRUD `/objectifs`, `GET /succes` | JWT requis. |

Les réponses d’erreur comprennent des statuts HTTP tels que 400, 401, 403, 404, 409 et 500. Les contrôleurs renvoient parfois les détails d’exception via le champ `error` dans les erreurs 500 : à éviter en production si ces détails révèlent des informations internes.

## 7. Données et persistance

### MongoDB

Les modèles principaux sont :

- **User** : email unique, mot de passe haché, profil, poids et historique de poids.
- **Programme** : utilisateur, nom, jours/exercices ordonnés, indicateur actif.
- **Seance** : utilisateur, date, exercices/séries, statut et date de validation.
- **Objectif** : type, valeur cible, réponses de motivation, statut et date cible.
- **Succes** : utilisateur, objectif lié, date d’obtention et description.

### Stockage mobile Hive

La boîte Hive `fittrack` stocke le token et l’utilisateur, l’état d’onboarding, le catalogue mis en cache, le programme actif mis en cache et l’historique local de poids. Les providers du catalogue et du programme actif retombent sur leurs caches si la requête échoue. Le provider d’historique des séances appelle l’API sans cache local dédié.

## 8. Configuration et lancement

### Backend

Variables d’environnement référencées par le code :

- `PORT` (défaut 3000 dans le serveur local),
- `MONGO_URI`,
- `JWT_SECRET`,
- `JWT_EXPIRES_IN`,
- `NODE_ENV` (contrôle le lancement du listener local),
- `GEMINI_API_KEY` (clé privée côté serveur),
- `GEMINI_MODEL` (défaut `gemini-3.8-flash`).

La génération appelle l’API REST Gemini depuis le backend. Le profil, les objectifs actifs et le catalogue sont transmis à Google pour produire la proposition ; la clé API reste côté backend et ne doit jamais être embarquée dans l’application. Gemini impose ses propres quotas, conditions et limites selon la clé et le modèle : la clé API ne signifie pas un usage littéralement illimité.

Démarrage local depuis `fittrack-backend/` :

```bash
npm install
npm run dev
```

`npm start` lance également `node server.js`. En environnement non-production, l’API écoute sur le port défini par `PORT` ou 3000. Le catalogue Swagger se consulte à `/api-docs`.

### Mobile

Variables d’environnement attendues dans le fichier `.env` Flutter : `API_BASE_URL` pointant vers la base `/api` appropriée. Pour un émulateur Android local, le README indique `http://10.0.2.2:3000/api`.

```bash
flutter pub get
flutter run
```

Le SDK Dart doit respecter la contrainte `>=3.5.0 <4.0.0`. La compilation Android/iOS dépend aussi de leurs SDK et chaînes de signature habituelles.

### Génération et qualité

Commandes documentées dans le dépôt :

```bash
dart format lib test
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

Les commandes de génération ne sont nécessaires que si les sources annotées correspondantes changent. Aucun build ni test n’a été exécuté pour cette analyse documentaire.

## 9. Sécurité, exploitation et risques constatés

### Priorité : secrets dans Git

`git ls-files` confirme que `fittrack-backend/.env` est suivi par Git. Son contenu n’a pas été ouvert ni reproduit. Les valeurs sensibles qui y figureraient doivent être considérées comme exposées : les remplacer/faire tourner, retirer le fichier de l’index et du dépôt selon la procédure de l’équipe, puis utiliser un `.env.example` sans secrets. Ajouter ou vérifier les règles d’exclusion. Un fichier déjà suivi reste suivi même après ajout à `.gitignore`.

Pour la clé Gemini locale, le serveur charge désormais `fittrack-backend/.env.local` avant `.env` ; `.env.local` est ignoré par Git. Ajouter `GEMINI_API_KEY` dans ce fichier ou dans le gestionnaire de secrets de l’environnement de déploiement, jamais dans le `.env` suivi ou dans Flutter.

Un fichier `fittrack_mobile_flutter/.env` existe dans le workspace mais n’est pas suivi par Git. Ne pas y placer de secrets serveur : les valeurs intégrées dans un binaire mobile peuvent être extraites.

### Autres constats techniques

- CORS autorise toutes les origines (`origin: "*"`). Restreindre aux origines voulues si l’API est exposée à des clients web.
- Pas de limitation de débit, de politique de verrouillage de compte ou de validation centralisée de schémas de requête visible dans les routes examinées.
- Les erreurs internes sont parfois renvoyées au client ; limiter les détails en production et privilégier une journalisation serveur contrôlée.
- La configuration JWT dépend de `JWT_SECRET` et de `JWT_EXPIRES_IN`. Valider explicitement la présence des variables au démarrage.
- Une configuration de déploiement Vercel est présente ; confirmer que le driver MongoDB et l’initialisation de connexion sont adaptés au cycle serverless réellement utilisé.
- Les fichiers d’environnement ne doivent pas être intégrés aux commits. `fittrack-backend/.gitignore` contient des règles `.env`, mais cela ne retire pas de l’index le fichier déjà suivi.

## 10. Limites et dette technique

- `workout_page.dart` compte environ 1 908 lignes et concentre une grande partie de l’interface et de l’état de séance ; poursuivre son découpage en widgets, contrôleurs et logique métier de domaine.
- Les marqueurs de séries terminées sont uniquement locaux à la page et ne changent pas les séances envoyées à l’API.
- L’historique complet des séances ne bénéficie pas du cache local présent pour les exercices et le programme actif.
- L’historique de poids local et l’historique de poids API coexistent ; définir clairement la source de vérité et les règles de synchronisation.
- Les médias couvrent le catalogue initial limité, pas nécessairement tous les exercices disponibles.
- Le calcul des objectifs de charge utilise la charge maximale brute, sans estimation 1RM ni distinction par exercice.
- Les règles des objectifs `poids_cible` / `perte_de_poids` méritent une validation fonctionnelle.
- La couverture présente des tests unitaires ciblés sur 1RM, dernières séries et médias, plus un widget test. Elle ne constitue pas une couverture exhaustive des routes, repositories, contrôleurs ou parcours complets.
- Le dépôt contient des répertoires d’artefacts locaux tels que `node_modules/`, `.dart_tool/`, `build/` et `.idea/` dans le workspace ; vérifier qu’ils restent exclus du contrôle de version.

## 11. Dépendance openGym et propriété intellectuelle

`openGym/` est un projet distinct sous licence AGPL-3.0, avec sa propre application web et ses propres services. Les règles du guide FitTrack demandent de s’inspirer des besoins et comportements, et de ne pas copier/traduire son code ni réutiliser ses médias. Pour toute réutilisation de code ou de contenus, effectuer une revue de licence séparée. Les images intégrées à FitTrack possèdent leur traçabilité dans le fichier `assets/exercises/NOTICE.md` de l’application mobile.

## 12. Priorités recommandées

1. Traiter le `.env` backend suivi par Git : faire tourner les secrets, retirer le fichier de l’index et contrôler l’historique selon la politique du dépôt.
2. Restreindre CORS, valider les variables obligatoires au démarrage et ne pas renvoyer les détails d’exceptions aux clients en production.
3. Clarifier le comportement attendu des objectifs poids cible/perte de poids et charge maximale ; ajouter des tests métier ciblés.
4. Décider si une séance validée peut être supprimée ; aligner le contrat et l’interface avec la règle d’immutabilité attendue.
5. Concevoir la persistance des séries réellement effectuées et le comportement de validation avant de modifier le modèle JSON.
6. Découper `workout_page.dart` et compléter les tests de repositories, API et parcours importants.
7. Définir une stratégie offline et une source de vérité pour les données de poids avant d’étendre le cache local.
8. Faire correspondre le document OpenAPI au comportement actuel des contrôleurs et maintenir la documentation lors des changements de contrat.

## 13. Sources principales consultées

- `CLAUDE.md` et `fittrack_mobile_flutter/README.md`.
- `fittrack_mobile_flutter/pubspec.yaml`, `lib/main.dart`, `lib/core/`, `lib/features/` et `test/`.
- `fittrack-backend/package.json`, `server.js`, `routes/`, `controllers/`, `models/`, `middlewares/`, `utils/`, `data/` et `swagger.json`.
- `fittrack_mobile_flutter/assets/exercises/NOTICE.md`.
- `openGym/README.md` et `openGym/LICENSE` pour identifier le périmètre et la licence du projet tiers.

> **Note de fiabilité :** cette fiche est une lecture du code présent dans le workspace à la date indiquée. Les fichiers Flutter `auth_pages.dart` et `home_page.dart` avaient des modifications locales non commitées pendant l’analyse ; leur contenu n’a pas été modifié dans le cadre de cette documentation.
