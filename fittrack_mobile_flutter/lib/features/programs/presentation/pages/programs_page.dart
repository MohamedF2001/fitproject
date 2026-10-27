import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';

class ProgramsPage extends ConsumerStatefulWidget {
  const ProgramsPage({super.key});

  @override
  ConsumerState<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends ConsumerState<ProgramsPage> {
  bool _isAutoAdding = false;
  bool _isGeneratingProposal = false;

  Future<ProgrammeProposalRequest> _buildProposalRequestFromGoals() async {
    int daysPerWeek = 3;
    String level = 'debutant';
    final objectiveParts = <String>[];

    try {
      final goals = await ref.read(goalsApiProvider).list();
      final activeGoals = goals.where((g) => g.statut == 'en_cours').toList();
      for (final g in activeGoals) {
        if (g.type == 'regularite_seances' && g.valeurCible != null) {
          daysPerWeek = g.valeurCible!.toInt().clamp(1, 7);
        }
        objectiveParts.add('${g.type}${g.valeurCible != null ? ' (cible: ${g.valeurCible})' : ''}');
      }
    } catch (_) {}

    final objectifText = objectiveParts.isNotEmpty
        ? objectiveParts.join(', ')
        : 'forme générale et progression régulière';

    return ProgrammeProposalRequest(
      joursParSemaine: daysPerWeek,
      niveau: level,
      objectif: objectifText,
      equipement: 'matériel standard de salle / poids du corps',
    );
  }

  Future<void> _autoAddProgram() async {
    if (_isAutoAdding) return;

    // 1. Check if user has active goals
    try {
      final goals = await ref.read(goalsApiProvider).list();
      final activeGoals = goals.where((g) => g.statut == 'en_cours').toList();
      if (activeGoals.isEmpty) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.flag_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Objectif requis'),
              ],
            ),
            content: const Text(
              'Vous devez d’abord définir au moins un objectif fitness en cours avant de pouvoir générer un programme automatique en fonction de vos objectifs.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.push('/goals');
                },
                icon: const Icon(Icons.add),
                label: const Text('Définir un objectif'),
              ),
            ],
          ),
        );
        return;
      }
    } catch (_) {}

    setState(() => _isAutoAdding = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Génération automatique de votre programme en cours, veuillez patienter...',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final request = await _buildProposalRequestFromGoals();
      final proposal = await ref.read(programsApiProvider).propose(request);
      if (!mounted) return;

      final currentPrograms = await ref.read(programsApiProvider).list();
      if (currentPrograms.isEmpty) {
        await ref.read(programsApiProvider).create(
              ProgrammeInput(
                nom: proposal.nom.isNotEmpty ? proposal.nom : 'Programme sur mesure',
                jours: proposal.jours,
                actif: true,
              ),
            );
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
      ref.invalidate(programsProvider);
      ref.invalidate(activeProgramProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Programme généré et ajouté avec succès !')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAutoAdding = false);
      }
    }
  }

  Future<void> _showProgramProposalDialog() async {
    setState(() => _isGeneratingProposal = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Proposition de programme en cours, veuillez patienter...',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final request = await _buildProposalRequestFromGoals();
      final proposal = await ref.read(programsApiProvider).propose(request);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
      setState(() => _isGeneratingProposal = false);

      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(proposal.nom)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Proposition basée sur vos objectifs :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  proposal.justification,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(
                  'Planning (${proposal.jours.length} jours) :',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ...proposal.jours.map((jour) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${jour.jour} (${jour.exercices.length} exercices)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            'Enregistrement du programme en cours...',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                final result = await executeApi(
                  () => ref.read(programsApiProvider).create(
                        ProgrammeInput(
                          nom: proposal.nom,
                          jours: proposal.jours,
                          actif: false,
                        ),
                      ),
                  ref.read(dioClientProvider),
                );

                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop(); // dismiss saving dialog

                if (result.isSuccess) {
                  ref.invalidate(programsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Programme suggéré enregistré en réserve !')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.failure!.message)),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog if open
      setState(() => _isGeneratingProposal = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suggestion : $e')),
      );
    }
  }

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
  Widget build(BuildContext context) => AppShell(
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fitness_center_outlined,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Aucun programme actif',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cliquez sur le bouton ci-dessous pour générer automatiquement votre programme d’entraînement en fonction de vos objectifs.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child:
                            AppButton(
                              label: 'Générer mon programme',
                              icon: Icons.check,
                              onPressed: _isAutoAdding ? null : _autoAddProgram,
                            ),
                            /*FilledButton.icon(
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: _isAutoAdding ? null : _autoAddProgram,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Générer mon programme'),
                            ),*/
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child:
                            AppButtonOutlined(
                              label: 'Créer un programme manuellement',
                              icon: Icons.add,
                              onPressed: () => context.push('/programs/create'),
                            ),
                            /*OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () => context.push('/programs/create'),
                              icon: const Icon(Icons.add),
                              label: const Text('Créer un programme manuellement'),
                            ),*/
                          ),
                        ],
                      ),
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
                    // Suggestion Card based on goals
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Suggestion de programme',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              if (_isGeneratingProposal)
                                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Besoin de changement ? Obtenez une nouvelle proposition sur mesure basée sur vos objectifs actuels.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isGeneratingProposal ? null : _showProgramProposalDialog,
                              icon: const Icon(Icons.lightbulb_outline),
                              label: const Text('Suggérer un nouveau programme'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

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
                  label: const Text(
                    style: TextStyle(fontSize: 12),
                    'Modifier',
                  ),
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
                  label: const Text(
                    style: TextStyle(fontSize: 12),
                    'Séances',
                  ),
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
                      'Définir comme actif',
                    ),
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
