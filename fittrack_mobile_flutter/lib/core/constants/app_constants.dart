class AppConstants {
  static const appName = 'FitTrack';
  static const apiBaseUrl = 'API_BASE_URL';
  static const tokenKey = 'token';
  static const userKey = 'user';
  static const exercisesCacheKey = 'exercises';
  static const activeProgramCacheKey = 'active_program';
  static const weightHistoryKey = 'weight_history';
  static const profileCompletePath = '/complete-profile';
  static const publicPaths = ['/splash', '/login', '/register', '/exercises'];
}

const weekDays = <String>[
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

const goalTypes = <String>[
  'perte_de_poids',
  'prise_de_muscle',
  'regularite_seances',
  'poids_cible',
];
