import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/exercise_media_widgets.dart';

class ExercisesPage extends ConsumerStatefulWidget {
  const ExercisesPage({super.key});

  @override
  ConsumerState<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends ConsumerState<ExercisesPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
        title: 'Catalogue exercices',
        child: ref.watch(exercisesProvider).when(
              loading: () => const AppLoader(),
              error: (error, _) => AppError(
                failureMessage(error),
                onRetry: () => ref.invalidate(exercisesProvider),
              ),
              data: (groups) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.md,
                  AppSpacing.screen,
                  AppSpacing.xl,
                ),
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un exercice ou un muscle',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final group in groups)
                    Builder(
                      builder: (_) {
                        final exercises = group.exercices
                            .where((exercise) =>
                                _query.trim().isEmpty ||
                                exercise.nameFr
                                    .toLowerCase()
                                    .contains(_query.toLowerCase()) ||
                                group.muscle
                                    .toLowerCase()
                                    .contains(_query.toLowerCase()))
                            .toList();
                        if (exercises.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                group.muscle,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            for (final exercise in exercises)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: AppCard(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: ExerciseThumb(
                                      exerciseId: exercise.id,
                                      size: 44,
                                    ),
                                    title: Text(exercise.nameFr,style: TextStyle(
                                      fontSize: 14,fontWeight: FontWeight.w500,
                                    ),),
                                    subtitle: Text(
                                      [exercise.category, exercise.equipment]
                                          .where((value) => value.isNotEmpty)
                                          .join(' • '),
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => showDialog<void>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(exercise.nameFr),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ExerciseDemo(
                                              exerciseId: exercise.id,
                                              height: 160,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              exercise.descriptionFr.isEmpty
                                                  ? 'Aucune description disponible.'
                                                  : exercise.descriptionFr,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
      );
}
