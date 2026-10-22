import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';

class CreateProgramPage extends ConsumerStatefulWidget {
  const CreateProgramPage({super.key, this.programToEdit});

  final ProgrammeModel? programToEdit;

  @override
  ConsumerState<CreateProgramPage> createState() => _CreateProgramPageState();
}

class _CreateProgramPageState extends ConsumerState<CreateProgramPage> {
  final _name = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _days = <JourModel>[];
  final _selectedExercises = <String>{};
  String _selectedDay = weekDays.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.programToEdit != null) {
      _name.text = widget.programToEdit!.nom;
      _days.addAll(widget.programToEdit!.jours);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _addDay() {
    final existingIndex = _days.indexWhere((day) => day.jour == _selectedDay);
    final newJour = JourModel(
      jour: _selectedDay,
      exercices: _selectedExercises
          .map((id) => ExerciceProgrammeModel(
                exerciceId: id,
                ordre: _selectedExercises.toList().indexOf(id) + 1,
              ))
          .toList(),
    );

    setState(() {
      if (existingIndex >= 0) {
        _days[existingIndex] = newJour;
      } else {
        _days.add(newJour);
      }
      _selectedExercises.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existingIndex >= 0
              ? 'Jour $_selectedDay mis à jour'
              : 'Jour $_selectedDay ajouté avec success',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editDay(JourModel day) {
    setState(() {
      _selectedDay = day.jour;
      _selectedExercises.clear();
      _selectedExercises.addAll(day.exercices.map((e) => e.exerciceId));
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins un jour au programme')),
      );
      return;
    }
    setState(() => _saving = true);

    final input = ProgrammeInput(
      nom: _name.text.trim(),
      jours: _days,
      actif: widget.programToEdit?.actif ?? false,
    );

    final result = widget.programToEdit != null
        ? await executeApi(
            () => ref.read(programsApiProvider).update(
                  widget.programToEdit!.id,
                  input,
                ),
            ref.read(dioClientProvider),
          )
        : await executeApi(
            () => ref.read(programsApiProvider).create(input),
            ref.read(dioClientProvider),
          );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.isSuccess) {
      ref.invalidate(programsProvider);
      ref.invalidate(activeProgramProvider);
      context.go('/programs');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider);
    final isEditing = widget.programToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le programme' : 'Création d\'un programme'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nom du programme',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Nom requis' : null,
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Configuration des jours'),
            if (_days.isNotEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jours configurés (${_days.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    for (final day in _days)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today,
                            color: AppColors.primary),
                        title: Text(
                          style: TextStyle(fontSize: 12),
                            day.jour),
                        subtitle: Text(
                          style: const TextStyle(fontSize: 12),
                            '${day.exercices.length} exercice(s)'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _editDay(day),
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: 'Modifier les exercices',
                            ),
                            IconButton(
                              onPressed: () => setState(() => _days.remove(day)),
                              icon: const Icon(Icons.close, color: Colors.redAccent),
                              tooltip: 'Supprimer ce jour',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedDay,
                    decoration: const InputDecoration(labelText: 'Sélectionner le jour'),
                    items: weekDays
                        .map((day) =>
                            DropdownMenuItem(value: day, child: Text(day)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedDay = value ?? weekDays.first),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add),
                  tooltip: 'Enregistrer le jour',
                ),
              ],
            ),
            const SizedBox(height: 12),
            exercises.when(
              loading: () => const AppCard(child: AppLoader()),
              error: (error, _) => AppError(failureMessage(error)),
              data: (groups) {
                final all = groups.expand((group) => group.exercices).toList();
                if (all.isEmpty) {
                  return const AppCard(
                    child: Text('Aucun exercice disponible.'),
                  );
                }
                return AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Exercices / $_selectedDay',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${_selectedExercises.length} sélectionné(s)',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      for (final exercise in all)
                        CheckboxListTile(
                          value: _selectedExercises.contains(exercise.id),
                          dense: true,
                          activeColor: AppColors.primary,
                          checkColor: AppColors.onPrimary,
                          title: Text(exercise.nameFr),
                          subtitle: Text(
                            [exercise.category, exercise.equipment]
                                .where((value) => value.isNotEmpty)
                                .join(' • '),
                          ),
                          onChanged: (checked) => setState(() {
                            if (checked == true) {
                              _selectedExercises.add(exercise.id);
                            } else {
                              _selectedExercises.remove(exercise.id);
                            }
                          }),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            AppButton(
              label: isEditing
                  ? 'Enregistrer les modifications'
                  : 'Enregistrer le programme',
              icon: Icons.check,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
