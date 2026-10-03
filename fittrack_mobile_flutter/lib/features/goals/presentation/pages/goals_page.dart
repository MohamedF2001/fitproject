import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';

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
              data: (goals) => goals.isEmpty
                  ? EmptyState(
                      title: 'Définis un objectif qui te ressemble',
                      action: FilledButton(
                        onPressed: () => _create(context, ref),
                        child: const Text('Ajouter'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.md,
                        AppSpacing.screen,
                        100,
                      ),
                      itemCount: goals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final goal = goals[index];
                        return AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.track_changes,
                                color: AppColors.primary),
                            title: Text(
                              goal.type.replaceAll('_', ' '),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              [
                                if (goal.valeurCible != null)
                                  'Cible : ${goal.valeurCible}',
                                if (goal.questionsMotivation.isNotEmpty)
                                  goal.questionsMotivation.first.reponse,
                              ].join('\n'),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StatusChip(goal.statut),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
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
                                          Icon(Icons.edit, size: 20),
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
                                              size: 20),
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
                          ),
                        );
                      },
                    ),
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
      title: const Text('Nouvel objectif'),
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



