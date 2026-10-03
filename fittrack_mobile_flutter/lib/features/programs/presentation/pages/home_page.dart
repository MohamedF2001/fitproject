import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return AppShell(
      title: 'Accueil',
      action: IconButton(
        onPressed: () => context.go('/profile'),
        icon: const Icon(Icons.person_outline),
      ),
      /*floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => context.go('/workouts'),
        child: const Icon(Icons.fitness_center),
      ),*/
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeProgramProvider);
          ref.invalidate(workoutsProvider);
          await ref.read(authProvider.notifier).refreshProfile();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            100,
          ),
          children: [
            Text(
              'Bonjour ${user?.prenom ?? ''}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Prêt à bouger ?',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.surface3,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      user?.email ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const StatusChip('Actif'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ValueCard(
                    label: 'Poids',
                    value: user?.poids == null ? '—' : '${user!.poids} kg',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ValueCard(
                    label: 'Taille',
                    value: user?.taille == null ? '—' : '${user!.taille} m',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionTitle(
              title: 'Programme actif',
              action: TextButton(
                onPressed: () => context.go('/programs'),
                child: const Text('Voir tout'),
              ),
            ),
            ref.watch(activeProgramProvider).when(
                  loading: () =>
                      const AppCard(child: LinearProgressIndicator()),
                  error: (error, _) => AppError(
                    failureMessage(error),
                    onRetry: () => ref.invalidate(activeProgramProvider),
                  ),
                  data: (program) => AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            program?.nom ?? 'Aucun programme actif',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (program != null)
                          Text(
                            '${program.jours.length} jours',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            SectionTitle(title: 'Actions rapides'),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.search,
                    label: 'Exercices',
                    onTap: () => context.push('/exercises'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.emoji_events_outlined,
                    label: 'Succès',
                    onTap: () => context.push('/achievements'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
}



class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AppCard(
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 9),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      );
}
