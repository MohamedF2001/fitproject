import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class AppPersistentShell extends StatelessWidget {
  const AppPersistentShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              );
            }
            return const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Programmes',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center),
              selectedIcon: Icon(Icons.fitness_center),
              label: 'Séances',
            ),
            NavigationDestination(
              icon: Icon(Icons.track_changes_outlined),
              selectedIcon: Icon(Icons.track_changes),
              label: 'Objectifs',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.title,
    required this.child,
    this.action,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'FITTRACK',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.bolt, color: AppColors.primary, size: 19),
          ],
        ),
        actions: [if (action != null) action!],
      ),
      body: child,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, this.action, super.key});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (action != null) action!
        ]),
      );
}
