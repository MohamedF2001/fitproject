import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/charts.dart';

IconData _getGoalIcon(String type) {
  final lower = type.toLowerCase();
  if (lower.contains('poids') || lower.contains('weight')) {
    return Icons.monitor_weight_rounded;
  } else if (lower.contains('muscle') || lower.contains('force')) {
    return Icons.fitness_center_rounded;
  } else if (lower.contains('regularite') || lower.contains('seance')) {
    return Icons.event_available_rounded;
  }
  return Icons.track_changes_rounded;
}

String _formatGoalType(String type) {
  if (type.isEmpty) return 'Objectif';
  final formatted = type.replaceAll('_', ' ').trim();
  return formatted[0].toUpperCase() + formatted.substring(1);
}

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final input = await showDialog<ObjectifInput>(
      context: context,
      builder: (_) => const _CreateGoalDialog(),
    );
    if (input == null) return;
    final result = await executeApi(
      () => ref.read(goalsApiProvider).create(input),
      ref.read(dioClientProvider),
    );
    if (!context.mounted) return;
    if (result.isSuccess) {
      ref.invalidate(goalsProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ObjectifModel goal,
  ) async {
    final input = await showDialog<ObjectifInput>(
      context: context,
      builder: (_) => _EditGoalDialog(goal: goal),
    );
    if (input == null) return;
    final result = await executeApi(
      () => ref.read(goalsApiProvider).update(goal.id, input),
      ref.read(dioClientProvider),
    );
    if (!context.mounted) return;
    if (result.isSuccess) {
      ref.invalidate(goalsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objectif mis à jour')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ObjectifModel goal,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'objectif'),
        content: Text(
          'Es-tu sûr de vouloir supprimer l\'objectif "${goal.type.replaceAll('_', ' ')}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await executeApi(
      () => ref.read(goalsApiProvider).delete(goal.id),
      ref.read(dioClientProvider),
    );

    if (!context.mounted) return;

    if (result.isSuccess) {
      ref.invalidate(goalsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objectif supprimé')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppShell(
        title: 'Mes objectifs',
        action: IconButton(
          onPressed: () => _create(context, ref),
          icon: const Icon(Icons.add),
        ),
        child: ref.watch(goalsProvider).when(
              loading: () => const AppLoader(),
              error: (error, _) => AppError(
                failureMessage(error),
                onRetry: () => ref.invalidate(goalsProvider),
              ),
              data: (goals) {
                final auth = ref.watch(authProvider);
                final workoutsAsync = ref.watch(workoutsProvider);
                final user = auth.user;
                final workouts = workoutsAsync.asData?.value ?? const [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.md,
                    AppSpacing.screen,
                    100,
                  ),
                  children: [
                    // Charge progression chart
                    ChargeEvolutionGraphWidget(seances: workouts),
                    const SizedBox(height: 16),

                    // Weight evolution chart
                    if (user != null) ...[
                      PoidsEvolutionGraphWidget(
                        historiquePoids: user.historiquePoids.isNotEmpty
                            ? user.historiquePoids
                            : (user.poids != null
                                ? [
                                    PoidsEntreeModel(
                                        poids: user.poids!,
                                        date: DateTime.now())
                                  ]
                                : const []),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mes objectifs actifs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _create(context, ref),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nouveau'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (goals.isEmpty)
                      EmptyState(
                        title: 'Définis un objectif qui te ressemble',
                        action: FilledButton(
                          onPressed: () => _create(context, ref),
                          child: const Text('Ajouter un objectif'),
                        ),
                      )
                    else
                      ...goals.map((goal) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getGoalIcon(goal.type),
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatGoalType(goal.type),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (goal.valeurCible != null) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.flag_outlined,
                                                    size: 10,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'Cible : ${goal.valeurCible} ${goal.type.contains('poids') ? 'kg' : ''}',
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      StatusChip(goal.statut),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.more_vert,
                                            color: AppColors.textMuted,
                                            size: 18),
                                        onSelected: (action) {
                                          if (action == 'edit') {
                                            _edit(context, ref, goal);
                                          } else if (action == 'delete') {
                                            _delete(context, ref, goal);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 10),
                                                SizedBox(width: 8),
                                                Text('Modifier'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    color: AppColors.error,
                                                    size: 10),
                                                SizedBox(width: 8),
                                                Text('Supprimer',
                                                    style: TextStyle(
                                                        color: AppColors.error)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (goal.questionsMotivation.isNotEmpty &&
                                      goal.questionsMotivation.first.reponse
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface1
                                            .withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.05),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.format_quote_rounded,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              goal.questionsMotivation.first
                                                  .reponse,
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )),
                  ],
                );
              },
            ),
      );
}

class _CreateGoalDialog extends StatefulWidget {
  const _CreateGoalDialog();

  @override
  State<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<_CreateGoalDialog> {
  final _targetController = TextEditingController();
  final _answerController = TextEditingController();
  final _customTypeController = TextEditingController();
  String _selectedType = goalTypes.first;

  @override
  void dispose() {
    _targetController.dispose();
    _answerController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width * 0.9;
    return AlertDialog(
      title: const Text(
        style: TextStyle(
          fontSize: 18
        ),
          'Nouvel objectif'),
      content: SizedBox(
        width: dialogWidth > 480 ? 480 : dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  ...goalTypes.map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          style: TextStyle(fontSize: 12),
                            item.replaceAll('_', ' ')),
                      )),
                  const DropdownMenuItem(
                    value: 'autre',
                    child: Text(
                      style: TextStyle(fontSize: 12),
                        'Autre (personnalisé)'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedType = value ?? _selectedType),
              ),
              if (_selectedType == 'autre') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customTypeController,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 12),
                    labelText: 'Type d\'objectif personnalisé',
                    hintText: 'ex: Endurance, Souplesse...',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelStyle: TextStyle(fontSize: 12),
                    labelText: 'Valeur cible'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _answerController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintMaxLines: 2,
                  labelStyle: TextStyle(fontSize: 12),
                  labelText: 'Pourquoi cet objectif ? (optionnel)',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            final value = double.tryParse(_targetController.text);
            final motivation = _answerController.text.trim();
            final customType = _customTypeController.text.trim();
            final finalType = _selectedType == 'autre'
                ? (customType.isNotEmpty ? customType : 'autre')
                : _selectedType;

            Navigator.pop(
              context,
              ObjectifInput(
                type: finalType,
                valeurCible: value,
                reponses: motivation.isEmpty ? const [] : [motivation],
              ),
            );
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

class _EditGoalDialog extends StatefulWidget {
  const _EditGoalDialog({required this.goal});
  final ObjectifModel goal;

  @override
  State<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<_EditGoalDialog> {
  late final TextEditingController _targetController;
  late final TextEditingController _answerController;
  late final TextEditingController _customTypeController;
  late String _selectedType;
  late String _selectedStatut;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(
      text: widget.goal.valeurCible?.toString() ?? '',
    );
    _answerController = TextEditingController(
      text: widget.goal.questionsMotivation.isNotEmpty
          ? widget.goal.questionsMotivation.first.reponse
          : '',
    );
    if (goalTypes.contains(widget.goal.type)) {
      _selectedType = widget.goal.type;
      _customTypeController = TextEditingController();
    } else {
      _selectedType = 'autre';
      _customTypeController = TextEditingController(text: widget.goal.type);
    }
    _selectedStatut = widget.goal.statut;
  }

  @override
  void dispose() {
    _targetController.dispose();
    _answerController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width * 0.9;
    return AlertDialog(
      title: const Text('Modifier l\'objectif'),
      content: SizedBox(
        width: dialogWidth > 480 ? 480 : dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  ...goalTypes.map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.replaceAll('_', ' ')),
                      )),
                  const DropdownMenuItem(
                    value: 'autre',
                    child: Text('Autre (personnalisé)'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedType = value ?? _selectedType),
              ),
              if (_selectedType == 'autre') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Type d\'objectif personnalisé',
                    hintText: 'ex: Endurance, Souplesse...',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatut,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: const [
                  DropdownMenuItem(
                    value: 'en_cours',
                    child: Text('En cours'),
                  ),
                  DropdownMenuItem(
                    value: 'atteint',
                    child: Text('Atteint'),
                  ),
                  DropdownMenuItem(
                    value: 'abandonne',
                    child: Text('Abandonné'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedStatut = value ?? _selectedStatut),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Valeur cible'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _answerController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Pourquoi cet objectif ? (optionnel)',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            final value = double.tryParse(_targetController.text);
            final motivation = _answerController.text.trim();
            final customType = _customTypeController.text.trim();
            final finalType = _selectedType == 'autre'
                ? (customType.isNotEmpty ? customType : 'autre')
                : _selectedType;

            Navigator.pop(
              context,
              ObjectifInput(
                type: finalType,
                valeurCible: value,
                statut: _selectedStatut,
                reponses: motivation.isEmpty ? const [] : [motivation],
              ),
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
