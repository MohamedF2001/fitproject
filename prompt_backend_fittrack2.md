Tu es un expert Node.js/Express.js. Génère une API REST complète et
production-ready pour **FitTrack** (application de suivi fitness).

---

### 🧱 STACK TECHNIQUE
- Runtime : Node.js avec ES Modules (import/export)
- Framework : Express.js
- Base de données : MongoDB Atlas + Mongoose
- Auth : JWT (jsonwebtoken + bcrypt)
- Documentation : Swagger/OpenAPI 3.0 (swagger.json statique)
- Déploiement : Vercel (serverless)
- Autres : dotenv, cors
- ⚠️ Pas d'upload d'images pour le moment : ni Multer ni Cloudinary ne doivent être utilisés

---

### 📁 STRUCTURE DES DOSSIERS
Génère exactement cette architecture :

```
project/
├── config/
│   └── db.js                      # Connexion MongoDB Atlas
├── data/
│   └── exercises_by_muscle_fr.json # Catalogue statique d'exercices (lu en mémoire au démarrage)
├── models/
│   ├── User.js                    # Profil, objectifs, succès
│   ├── Programme.js                # Programme d'entrainement (jours/horaires/exercices)
│   └── Seance.js                   # Séance réalisée (séries, répétitions, charges)
├── controllers/
│   ├── authController.js
│   ├── userController.js           # Profil, objectifs, succès
│   ├── exerciceController.js       # Lecture du catalogue JSON
│   ├── programmeController.js
│   └── seanceController.js
├── routes/
│   ├── authRoutes.js
│   ├── userRoutes.js
│   ├── exerciceRoutes.js
│   ├── programmeRoutes.js
│   └── seanceRoutes.js
├── middlewares/
│   └── auth.js                    # verifyToken
├── utils/
│   └── goalsChecker.js             # Logique de vérification des objectifs/succès
├── swagger.json                    # Documentation OpenAPI 3.0 complète
├── server.js                       # Point d'entrée
├── vercel.json                     # Config déploiement Vercel
└── .env                            # Variables d'environnement
```

---

### 👤 SYSTÈME D'AUTHENTIFICATION
Un seul type d'utilisateur (pas d'Admin/Client) :

**Utilisateur**
- Champs de compte : email (unique), motDePasse (min 6 cars, hashé bcrypt genSalt 10)
- Champs de profil (renseignés à la première connexion, modifiables ensuite) : nom, prenom, poids, taille
- Inscription : `POST /api/auth/register` → email + motDePasse
- Connexion : `POST /api/auth/login` → email + motDePasse
- Profil : `GET /api/auth/profile` et `PUT /api/auth/profile` (verifyToken)
- Méthode : comparePassword() via hook pre("save")
- JWT signé avec { userId } → expiresIn depuis .env
- Chaque utilisateur n'accède qu'à ses propres données (aucune notion d'admin dans ce projet)

---

### 🏋️ CATALOGUE D'EXERCICES (statique, pas de modèle Mongoose)
- Le fichier `data/exercises_by_muscle_fr.json` est chargé en mémoire au démarrage du serveur (pas de collection MongoDB dédiée)
- Structure : liste de groupes musculaires, chacun contenant une liste d'exercices (id, uuid, name_fr, description_fr, category, muscles_primary, muscles_secondary, equipment...)
- Route `GET /api/exercices` (publique) : retourne le catalogue, avec filtre optionnel par muscle ou catégorie (`?muscle=` / `?categorie=`)
- Route `GET /api/exercices/:id` (publique) : retourne un exercice précis
- Dans les modèles Programme et Seance, toute référence à un exercice se fait par **String** (id ou uuid du JSON), jamais par ObjectId Mongoose

---

### 📦 RESSOURCES MÉTIER

**1. Programme** (optionnel, un utilisateur peut n'en avoir aucun)
- utilisateur (ref User)
- nom (ex: "Programme minceur")
- jours : tableau de `{ jour (enum: Lundi..Dimanche), horaire (String type "07:00"), exercices: [{ exerciceId (String, ref catalogue), ordre }] }`
- actif (Boolean, un seul programme actif à la fois par utilisateur)
- date de création

**2. Seance** (séance réalisée)
- utilisateur (ref User)
- date
- exercices : tableau de `{ exerciceId (String, ref catalogue), series: [{ numero, repetitions, charge }], tempsRepos }`
- valideeLe (date de validation) / statut (brouillon / validee)

**3. Objectif** (embarqué dans User ou collection séparée référencée par User — choisis la collection séparée pour la lisibilité)
- utilisateur (ref User)
- type (ex: perte_de_poids, prise_de_muscle, regularite_seances, poids_cible)
- valeurCible (Number, optionnel selon le type)
- questionsMotivation : tableau de `{ question, reponse }` — un petit set de questions fixes posées à la création (ex: "Pourquoi cet objectif est important pour toi ?", "Combien de temps par semaine peux-tu y consacrer ?")
- statut (en_cours / atteint / abandonne)
- dateCreation, dateCible

**4. Succes**
- utilisateur (ref User)
- objectif (ref Objectif)
- dateObtention
- description (généré automatiquement, ex: "Objectif poids atteint : 75kg")

---

### 🔐 MATRICE DES PERMISSIONS
Un seul rôle (Utilisateur authentifié), toutes les routes protégées sauf le catalogue d'exercices :

| Route                          | Public | Utilisateur (propriétaire) |
|---------------------------------|--------|------------------------------|
| POST /auth/register             |  ✅    |                              |
| POST /auth/login                |  ✅    |                              |
| GET /auth/profile               |        |  ✅                          |
| PUT /auth/profile               |        |  ✅                          |
| GET /exercices                  |  ✅    |                              |
| GET /exercices/:id               |  ✅    |                              |
| GET/POST/PUT/DELETE /programmes  |        |  ✅ (ses propres programmes) |
| GET/POST/PUT/DELETE /seances     |        |  ✅ (ses propres séances)    |
| GET/POST/PUT /objectifs          |        |  ✅ (ses propres objectifs)  |
| GET /succes                      |        |  ✅ (ses propres succès)     |

---

### 🔁 LOGIQUE MÉTIER SPÉCIALE
- **Programme** : un utilisateur ne peut avoir qu'un seul programme `actif` à la fois (validation pre("save") : si un nouveau programme est marqué actif, désactiver les autres)
- **Programme** : si l'utilisateur n'a pas de programme actif, la route de consultation retourne un tableau/objet vide (le front n'affiche rien)
- **Seance** : une séance passe de statut `brouillon` à `validee` uniquement via une route dédiée `PUT /seances/:id/valider`, qui fige les données (plus de modification possible après validation)
- **Objectif → Succes** : après chaque séance validée ou mise à jour du poids dans le profil, exécuter `goalsChecker.js` qui vérifie tous les objectifs `en_cours` de l'utilisateur :
  - objectif de type `poids_cible` : comparer le poids actuel du profil à `valeurCible`
  - objectif de type `regularite_seances` : compter le nombre de séances validées sur une période
  - si la condition est remplie → créer un document `Succes`, passer l'objectif à `atteint`
- **Questions de motivation** : liste de questions fixes définie côté backend (constante), posées à la création d'un objectif ; les réponses sont stockées telles quelles, sans logique de scoring automatique (à affiner plus tard si besoin)

---

### ⚙️ SERVER.JS - CONFIGURATION
Configure server.js avec :
1. CORS : origin '*' (dev), methods GET/POST/PUT/DELETE/OPTIONS/PATCH
2. Connexion MongoDB au démarrage
3. Chargement du fichier `data/exercises_by_muscle_fr.json` en mémoire au démarrage
4. Routes via `app.use()` avec `express.json()` middleware
5. Swagger sur `/api-docs` via swagger.json statique
6. Export dual : `export default handler` (Vercel) + `app.listen()` si `!production`

---

### 📄 SWAGGER.JSON
Génère un swagger.json OpenAPI 3.0 complet avec :
- Tous les schemas (User, Programme, Seance, Objectif, Succes, AuthResponse, Error)
- Toutes les routes documentées avec request/response bodies
- Security scheme : bearerAuth (JWT)
- security: [] sur les routes publiques (auth register/login, exercices)
- Exemples de valeurs dans chaque schema
- Tags groupés par domaine (Auth, Utilisateur, Exercices, Programmes, Seances, Objectifs, Succes)

---

### 🌍 VARIABLES D'ENVIRONNEMENT (.env)
```
PORT=3000
NODE_ENV=development
MONGO_URI=mongodb+srv://...
JWT_SECRET=...
JWT_EXPIRES_IN=24h
```

---

### ✅ RÈGLES DE GÉNÉRATION
1. Utilise UNIQUEMENT ES Modules (import/export), jamais require()
2. Tous les controllers avec try/catch et messages d'erreur explicites
3. Logs console avec emojis (✅ ❌ 📤 etc.) pour le debug
4. Validation des champs obligatoires dans chaque controller
5. populate() sur toutes les références Mongoose dans les réponses (Programme.utilisateur, Seance.utilisateur, Objectif.utilisateur, Succes.objectif, etc.)
6. vercel.json : route /* → server.js
7. Pas de code commenté dans la version finale
8. Aucune dépendance Multer/Cloudinary : ne pas générer de logique d'upload d'image
