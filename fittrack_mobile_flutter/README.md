# FitTrack Mobile Flutter

Application Flutter Android/iOS connectée exclusivement aux routes documentées dans
`fittrack-backend/swagger.json`. L'interface utilise le design system sombre
**Kinetic Volt** et une Clean Architecture par fonctionnalité.

## Architecture

Chaque fonctionnalité suit le flux :

`presentation -> domain (use cases/repositories) -> data (datasources/models/repositories)`.

Les features sont organisées dans `lib/features/` :
`auth`, `exercises`, `programs`, `workouts`, `goals`, `achievements` et
`settings`. Le réseau, le stockage, les erreurs, le thème et le routing sont
centralisés dans `lib/core/`, tandis que les composants transverses sont dans
`lib/shared/`.

## Lancer

```bash
cp .env.example .env
# Android emulator: API_BASE_URL=http://10.0.2.2:3000/api
flutter pub get
flutter run
```

Les modèles API et les entités de domaine sont séparés, avec conversions
explicites dans les repositories. Les datasources utilisent exclusivement les
routes documentées dans `fittrack-backend/swagger.json`.

## Vérifier et publier

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --release
flutter build ipa --release
```

La session JWT, le catalogue, le dernier programme et l'historique de poids local
sont conservés dans Hive. L'historique de poids est propre à cet appareil et n'est
pas synchronisé avec l'API.

API couverte : auth, exercices, programmes, séances, objectifs et succès. Aucun
endpoint additionnel n'est utilisé.
