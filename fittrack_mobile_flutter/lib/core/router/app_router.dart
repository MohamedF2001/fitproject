import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../features/achievements/presentation/pages/achievements_page.dart';
import '../../features/achievements/presentation/pages/success_page.dart';
import '../../features/auth/presentation/pages/auth_pages.dart';
import '../../features/exercises/presentation/pages/exercises_page.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/programs/presentation/pages/create_program_page.dart';
import '../../features/programs/presentation/pages/home_page.dart';
import '../../features/programs/presentation/pages/programs_page.dart';
import '../../features/settings/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/workouts/presentation/pages/workout_page.dart';
import '../../shared/widgets/app_shell.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final storage = ref.read(storageProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      const publicPaths = {
        '/splash',
        '/login',
        '/register',
        '/exercises',
        '/onboarding',
      };
      final location = state.matchedLocation;
      final isAuthPage = location == '/login' ||
          location == '/register' ||
          location == '/onboarding';
      final auth = ref.read(authProvider);

      if (location == '/splash') {
        return null;
      }

      if (!auth.isAuthenticated) {
        if (!storage.hasSeenOnboarding && location != '/onboarding') {
          return '/onboarding';
        }
        if (storage.hasSeenOnboarding && !publicPaths.contains(location)) {
          return '/login';
        }
        return null;
      }

      if (auth.isAuthenticated && isAuthPage) {
        return auth.user?.isComplete == true ? '/home' : '/complete-profile';
      }

      if (auth.isAuthenticated &&
          auth.user?.isComplete != true &&
          location != '/complete-profile' &&
          !publicPaths.contains(location)) {
        return '/complete-profile';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/complete-profile',
        builder: (_, __) => const ProfilePage(forceComplete: true),
      ),

      // Persistent Shell for 5 Main Tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppPersistentShell(navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/programs',
                builder: (_, __) => const ProgramsPage(),
              ),
              GoRoute(
                path: '/programs/create',
                builder: (context, state) => CreateProgramPage(
                  programToEdit: state.extra is ProgrammeModel
                      ? state.extra as ProgrammeModel
                      : null,
                ),
              ),
              GoRoute(
                path: '/programs/new',
                redirect: (_, __) => '/programs/create',
              ),
              GoRoute(
                path: '/programs/:id',
                builder: (_, __) => const ProgramsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workouts',
                builder: (_, __) => const WorkoutPage(),
              ),
              GoRoute(
                path: '/workouts/:id',
                builder: (_, __) => const WorkoutPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/goals', builder: (_, __) => const GoalsPage()),
              GoRoute(
                path: '/goals/create',
                builder: (_, __) => const GoalsPage(),
              ),
              GoRoute(
                path: '/goals/:id',
                builder: (_, __) => const GoalsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // Standalone Routes
      GoRoute(path: '/workout', redirect: (_, __) => '/workouts'),
      GoRoute(path: '/exercises', builder: (_, __) => const ExercisesPage()),
      GoRoute(
        path: '/achievements',
        builder: (_, __) => const AchievementsPage(),
      ),
      GoRoute(
        path: '/achievements/celebrate',
        builder: (_, state) => SuccessPage(
          achievements: state.extra is List<SuccesModel>
              ? state.extra! as List<SuccesModel>
              : const [],
        ),
      ),
      GoRoute(
        path: '/success',
        builder: (_, state) => SuccessPage(
          achievements: state.extra is List<SuccesModel>
              ? state.extra! as List<SuccesModel>
              : const [],
        ),
      ),
    ],
  );
});
