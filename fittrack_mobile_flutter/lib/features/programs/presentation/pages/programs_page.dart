import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';

class ProgramsPage extends ConsumerWidget {
  const ProgramsPage({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final result = await executeApi(
      () => ref.read(programsApiProvider).delete(id),
      ref.read(dioClientProvider),
    );
    if (!context.mounted) return;
    if (result.isSuccess) {
      await ref.read(storageProvider).cacheActiveProgram(null);
      if (!context.mounted) return;
      ref.invalidate(programsProvider);
      ref.invalidate(activeProgramProvider);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess ? 'Programme supprimé' : result.failure!.message,
        ),
      ),
    );
  }

  Future<void> _activate(
    BuildContext context,
    WidgetRef ref,
    ProgrammeModel program,
  ) async {
    final result = await executeApi(
      () => ref.read(programsApiProvider).update(
            program.id,
            ProgrammeInput(nom: program.nom, jours: program.jours, actif: true),
          ),
      ref.read(dioClientProvider),
    );
    if (!context.mounted) return;
    if (result.isSuccess) {
      ref.invalidate(programsProvider);
      ref.invalidate(activeProgramProvider);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppShell(
        title: 'Programmes',
        action: IconButton(
          onPressed: () => context.push('/programs/create'),
          icon: const Icon(Icons.add),
        ),
        child: ref.watch(programsProvider).when(
              loading: () => const AppLoader(),
              error: (error, _) => AppError(
                failureMessage(error),
                onRetry: () => ref.invalidate(programsProvider),
              ),
              data: (programs) {
                if (programs.isEmpty) {
                  return EmptyState(
                    title: 'Crée ton premier programme',
                    action: FilledButton.icon(
                      onPressed: () => context.push('/programs/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer un programme'),
                    ),
                  );
                }

                final activePrograms = programs.where((p) => p.actif).toList();
                final reservePrograms = programs.where((p) => !p.actif).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.md,
                    AppSpacing.screen,
                    100,
                  ),
                  children: [
                    // Section Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mes Programmes',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Planifiez votre progression sur mesure',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        /*FilledButton.tonalIcon(
                          onPressed: () => context.push('/programs/create'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Créer'),
                        ),*/
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Active Program Card
                    if (activePrograms.isNotEmpty) ...[
                      const Text(
                        'Programme actif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...activePrograms.map(
                          (program) => _buildActiveProgramCard(context, ref, program)),
                      const SizedBox(height: 24),
                    ],

                    // Reserve Programs Section
                    if (reservePrograms.isNotEmpty) ...[
                      Column(
                        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Autres programmes en réserve',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            '${reservePrograms.length} disponible(s)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...reservePrograms.map(
                        (program) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildReserveProgramCard(context, ref, program),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Bottom Create Button
                    AppButton(
                      label: 'Créer un nouveau programme',
                      icon: Icons.add_circle_outline,
                      onPressed: () => context.push('/programs/create'),
                      secondary: true,
                    ),
                  ],
                );
              },
            ),
      );

  Widget _buildActiveProgramCard(
      BuildContext context, WidgetRef ref, ProgrammeModel program) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Programme actif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.verified, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Text(
                    'En cours',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            program.nom,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${program.jours.length} ${program.jours.length > 1 ? 'séances' : 'séance'} / semaine • Personnalisé',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          if (program.jours.isNotEmpty) ...[
            Text(
              'PLANNING DE LA SEMAINE (${program.jours.length} SÉANCE${program.jours.length > 1 ? 'S' : ''})',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: program.jours.map((jour) {
                final count = jour.exercices.length;
                return Chip(
                  avatar: const Icon(Icons.fitness_center,
                      size: 14, color: AppColors.primary),
                  label: Text(
                    '${jour.jour}${count > 0 ? ' ($count exo${count > 1 ? 's' : ''})' : ''}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.surface2,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/programs/create', extra: program),
                  //icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    style: TextStyle(fontSize: 12),
                      'Modifier'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.go('/workouts'),
                  //icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text(
                    style: TextStyle(fontSize: 12),
                      'Séances'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _delete(context, ref, program.id),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReserveProgramCard(
      BuildContext context, WidgetRef ref, ProgrammeModel program) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StatusChip('Inactif'),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _activate(context, ref, program),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text(
                      style: TextStyle(fontSize: 11),
                        'Définir comme actif'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            program.nom,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${program.jours.length} ${program.jours.length > 1 ? 'séances' : 'séance'} planifiée(s)',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          if (program.jours.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: program.jours.map((jour) {
                final count = jour.exercices.length;
                return Chip(
                  avatar: const Icon(Icons.calendar_today,
                      size: 12, color: AppColors.textMuted),
                  label: Text(
                    '${jour.jour}${count > 0 ? ' ($count exo${count > 1 ? 's' : ''})' : ''}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: AppColors.surface2,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.push('/programs/create', extra: program),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Modifier'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _delete(context, ref, program.id),
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.redAccent),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
