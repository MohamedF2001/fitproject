import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  SeanceModel? _draft;
  bool _creating = false;

  // Rest Timer State
  Timer? _restTimer;
  int _timerDuration = 60;
  int _timerRemaining = 0;
  bool _timerIsRunning = false;
  String? _timerExerciseName;

  // Completed sets tracker (key format: "exerciseIndex_setIndex")
  final Set<String> _completedSets = {};

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  // --- Timer Controls ---

  void _startTimer(int seconds, [String? exerciseName]) {
    _restTimer?.cancel();
    setState(() {
      _timerDuration = max(seconds, 1);
      _timerRemaining = seconds;
      _timerIsRunning = true;
      if (exerciseName != null) {
        _timerExerciseName = exerciseName;
      }
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timerRemaining > 1) {
        setState(() => _timerRemaining--);
      } else {
        timer.cancel();
        setState(() {
          _timerRemaining = 0;
          _timerIsRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.alarm_on, color: AppColors.onPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _timerExerciseName != null
                        ? 'Repos terminé pour $_timerExerciseName ! À vous de jouer.'
                        : 'Temps de repos écoulé ! Place à la série suivante.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _pauseTimer() {
    _restTimer?.cancel();
    setState(() => _timerIsRunning = false);
  }

  void _resumeTimer() {
    if (_timerRemaining <= 0) return;
    setState(() => _timerIsRunning = true);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timerRemaining > 1) {
        setState(() => _timerRemaining--);
      } else {
        timer.cancel();
        setState(() {
          _timerRemaining = 0;
          _timerIsRunning = false;
        });
      }
    });
  }

  void _resetTimer() {
    _restTimer?.cancel();
    setState(() {
      _timerRemaining = 0;
      _timerIsRunning = false;
      _timerExerciseName = null;
    });
  }

  void _adjustTimer(int deltaSeconds) {
    setState(() {
      _timerRemaining = max(0, _timerRemaining + deltaSeconds);
      _timerDuration = max(_timerDuration, _timerRemaining);
      if (_timerRemaining > 0 && !_timerIsRunning) {
        _resumeTimer();
      }
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // --- API Actions ---

  Future<void> _create() async {
    final activeProgram = await ref.read(activeProgramProvider.future);
    List<ExerciceSeanceModel> prefilledExercises = [];

    if (activeProgram != null && activeProgram.jours.isNotEmpty) {
      if (!mounted) return;
      final selectedJour = await showDialog<JourModel?>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Démarrer une séance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Programme actif : ${activeProgram.nom}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              const Text('Choisissez le jour du programme à charger, ou démarrez une séance libre :'),
              const SizedBox(height: 12),
              ...activeProgram.jours.map((jour) => ListTile(
                    leading: const Icon(Icons.today, color: AppColors.primary),
                    title: Text('${jour.jour} (${jour.horaire})'),
                    subtitle: Text('${jour.exercices.length} exercice(s)'),
                    onTap: () => Navigator.pop(context, jour),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), // Séance libre
              child: const Text('Séance libre (sans jour)'),
            ),
          ],
        ),
      );

      if (selectedJour != null) {
        prefilledExercises = selectedJour.exercices
            .map((e) => ExerciceSeanceModel(
                  exerciceId: e.exerciceId,
                  series: const [
                    SerieModel(numero: 1, repetitions: 10, charge: 0),
                    SerieModel(numero: 2, repetitions: 10, charge: 0),
                    SerieModel(numero: 3, repetitions: 10, charge: 0),
                  ],
                  tempsRepos: 60,
                ))
            .toList();
      }
    }

    setState(() => _creating = true);
    final result = await executeApi(
      () => ref.read(workoutsApiProvider).create(
            SeanceInput(date: DateTime.now(), exercices: prefilledExercises),
          ),
      ref.read(dioClientProvider),
    );
    if (!mounted) return;
    setState(() {
      _creating = false;
      if (result.isSuccess) _draft = result.data;
    });
    if (result.isSuccess) ref.invalidate(workoutsProvider);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
    }
  }

  Future<void> _addExercise() async {
    final groups = await ref.read(exercisesProvider.future);
    final all = groups.expand((group) => group.exercices).toList();
    if (all.isEmpty || _draft == null || !mounted) return;
    final exercise = await showDialog<ExerciceSeanceModel>(
      context: context,
      builder: (_) => _AddExerciseDialog(exercises: all),
    );
    if (exercise == null || !mounted) return;
    await _saveExercises([..._draft!.exercices, exercise]);
  }

  Future<void> _editExercise(int exerciseIndex) async {
    final groups = await ref.read(exercisesProvider.future);
    final all = groups.expand((group) => group.exercices).toList();
    final draft = _draft;
    if (all.isEmpty ||
        draft == null ||
        exerciseIndex < 0 ||
        exerciseIndex >= draft.exercices.length ||
        !mounted) {
      return;
    }

    final currentItem = draft.exercices[exerciseIndex];
    final updatedItem = await showDialog<ExerciceSeanceModel>(
      context: context,
      builder: (_) => _EditExerciseDialog(
        exercises: all,
        initialItem: currentItem,
      ),
    );

    if (updatedItem == null || !mounted) return;

    final updatedExercices = List<ExerciceSeanceModel>.from(draft.exercices);
    updatedExercices[exerciseIndex] = updatedItem;
    await _saveExercises(updatedExercices);
  }

  Future<void> _addSetToExercise(
      int exerciseIndex, String exerciseName) async {
    final draft = _draft;
    if (draft == null ||
        exerciseIndex < 0 ||
        exerciseIndex >= draft.exercices.length) {
      return;
    }

    final exercise = draft.exercices[exerciseIndex];
    final currentSeries = exercise.series;

    final lastSet = currentSeries.isNotEmpty ? currentSeries.last : null;
    final nextNumber = currentSeries.length + 1;
    final newReps = lastSet?.repetitions ?? 10;
    final newCharge = lastSet?.charge ?? 0.0;

    final updatedSeries = [
      ...currentSeries,
      SerieModel(numero: nextNumber, repetitions: newReps, charge: newCharge),
    ];

    final updatedExercices = List<ExerciceSeanceModel>.from(draft.exercices);
    updatedExercices[exerciseIndex] = ExerciceSeanceModel(
      exerciceId: exercise.exerciceId,
      series: updatedSeries,
      tempsRepos: exercise.tempsRepos,
    );

    await _saveExercises(updatedExercices);
  }

  Future<void> _editSet(int exerciseIndex, int setIndex) async {
    final draft = _draft;
    if (draft == null) return;
    final exercise = draft.exercices[exerciseIndex];
    final serie = exercise.series[setIndex];

    final result = await showDialog<SerieModel>(
      context: context,
      builder: (_) => _EditSetDialog(
        setNumber: serie.numero,
        initialReps: serie.repetitions,
        initialCharge: serie.charge,
      ),
    );

    if (result == null || !mounted) return;

    final updatedSeries = List<SerieModel>.from(exercise.series);
    updatedSeries[setIndex] = result;

    final updatedExercices = List<ExerciceSeanceModel>.from(draft.exercices);
    updatedExercices[exerciseIndex] = ExerciceSeanceModel(
      exerciceId: exercise.exerciceId,
      series: updatedSeries,
      tempsRepos: exercise.tempsRepos,
    );

    await _saveExercises(updatedExercices);
  }

  Future<void> _removeSetFromExercise(
      int exerciseIndex, int setIndex) async {
    final draft = _draft;
    if (draft == null) return;
    final exercise = draft.exercices[exerciseIndex];
    final updatedSeries = List<SerieModel>.from(exercise.series)
      ..removeAt(setIndex);

    for (int i = 0; i < updatedSeries.length; i++) {
      updatedSeries[i] = SerieModel(
        numero: i + 1,
        repetitions: updatedSeries[i].repetitions,
        charge: updatedSeries[i].charge,
      );
    }

    final updatedExercices = List<ExerciceSeanceModel>.from(draft.exercices);
    updatedExercices[exerciseIndex] = ExerciceSeanceModel(
      exerciceId: exercise.exerciceId,
      series: updatedSeries,
      tempsRepos: exercise.tempsRepos,
    );

    await _saveExercises(updatedExercices);
  }

  Future<void> _updateExerciseRestTime(
      int exerciseIndex, int newRestSeconds) async {
    final draft = _draft;
    if (draft == null) return;
    final exercise = draft.exercices[exerciseIndex];

    final updatedExercices = List<ExerciceSeanceModel>.from(draft.exercices);
    updatedExercices[exerciseIndex] = ExerciceSeanceModel(
      exerciceId: exercise.exerciceId,
      series: exercise.series,
      tempsRepos: newRestSeconds,
    );

    await _saveExercises(updatedExercices);
  }

  Future<void> _saveExercises(List<ExerciceSeanceModel> exercises) async {
    final draft = _draft;
    if (draft == null) return;
    final result = await executeApi(
      () => ref.read(workoutsApiProvider).update(
            draft.id,
            SeanceInput(date: draft.date, exercices: exercises),
          ),
      ref.read(dioClientProvider),
    );
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() => _draft = result.data);
      ref.invalidate(workoutsProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
    }
  }

  Future<void> _validate() async {
    final draft = _draft;
    if (draft == null) return;
    final result = await executeApi(
      () => ref.read(workoutsApiProvider).validate(draft.id),
      ref.read(dioClientProvider),
    );
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() => _draft = null);
      ref.invalidate(workoutsProvider);
      ref.invalidate(achievementsProvider);
      context.go('/success', extra: result.data!.succesObtenus);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workouts = ref.watch(workoutsProvider);
    final exercisesAsync = ref.watch(exercisesProvider);

    // Map exercise IDs/UUIDs to french names
    final exerciseNames = <String, String>{};
    if (exercisesAsync.hasValue) {
      for (final group in exercisesAsync.value!) {
        for (final ex in group.exercices) {
          exerciseNames[ex.id] = ex.nameFr;
          if (ex.uuid.isNotEmpty) {
            exerciseNames[ex.uuid] = ex.nameFr;
          }
        }
      }
    }

    if (_draft == null && workouts.hasValue) {
      final drafts = workouts.value!
          .where((workout) => workout.statut != 'validee')
          .toList();
      if (drafts.isNotEmpty) _draft = drafts.first;
    }
    final draft = _draft;

    return AppShell(
      title: 'Séance en cours',
      action: IconButton(
        onPressed: _creating || draft != null ? null : _create,
        icon: const Icon(Icons.add),
      ),
      child: draft == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fitness_center,
                          color: AppColors.primary, size: 48),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Commence une séance',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crée un brouillon puis ajoute les exercices et leurs séries pour suivre votre progression en direct.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Démarrer la séance',
                      icon: Icons.play_arrow,
                      onPressed: _creating ? null : _create,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Floating Sticky Rest Timer Bar pinned at top when running
                if (_timerRemaining > 0) _buildStickyFloatingTimerBar(),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.md,
                      AppSpacing.screen,
                      120,
                    ),
                    children: [
                      // Live Telemetry Header Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.bolt,
                                        size: 16, color: AppColors.primary),
                                    SizedBox(width: 6),
                                    Text(
                                      'LIVE TÉLÉMÉTRIE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                StatusChip(draft.statut),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SÉANCE ACTIVE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      draft.date == null
                                          ? 'Séance du jour'
                                          : DateFormat('EEEE dd MMM', 'fr')
                                              .format(draft.date!),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'EXERCICES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${draft.exercices.length}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rest Timer Detailed Controls Card
                      _buildRestTimerCard(),
                      const SizedBox(height: 16),

                      // Exercises List
                      if (draft.exercices.isEmpty)
                        AppCard(
                          child: Column(
                            children: [
                              const Icon(Icons.fitness_center,
                                  size: 36, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'Aucun exercice ajouté',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Commencez par ajouter votre premier exercice à cette séance.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _addExercise,
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter un exercice'),
                              ),
                            ],
                          ),
                        )
                      else
                        ...draft.exercices.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final exerciseName =
                              exerciseNames[item.exerciceId] ?? item.exerciceId;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Exercise Card Header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'EXERCICE ${index + 1}/${draft.exercices.length}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                _editExercise(index),
                                            tooltip: 'Modifier l\'exercice',
                                            icon: const Icon(
                                                Icons.edit_note_rounded,
                                                size: 22,
                                                color: AppColors.primary),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              final updated =
                                                  List<ExerciceSeanceModel>.from(
                                                      draft.exercices)
                                                    ..removeAt(index);
                                              _saveExercises(updated);
                                            },
                                            tooltip: 'Supprimer l\'exercice',
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                                color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    exerciseName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Rest Time Configuration Row for Exercise
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.timer_outlined,
                                            size: 18, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Repos : ${_formatDuration(item.tempsRepos)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: () => _showChangeRestDialog(
                                              index, item.tempsRepos),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 4),
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit,
                                                    size: 14,
                                                    color: AppColors.primary),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Modifier',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: () => _startTimer(
                                              item.tempsRepos, exerciseName),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.play_arrow,
                                                    size: 14,
                                                    color: AppColors.primary),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Démarrer repos',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Sets Header Row
                                  const Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text('SÉRIE',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textMuted)),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text('CHARGE',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textMuted)),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text('REPS',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textMuted)),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text('ACTIONS',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textMuted)),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),

                                  // Sets Rows
                                  if (item.series.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'Aucune série. Cliquez sur "+ Ajouter une série".',
                                        style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 13),
                                      ),
                                    )
                                  else
                                    ...item.series
                                        .asMap()
                                        .entries
                                        .map((serieEntry) {
                                      final sIndex = serieEntry.key;
                                      final serie = serieEntry.value;
                                      final setKey = '${index}_$sIndex';
                                      final isDone =
                                          _completedSets.contains(setKey);

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 3),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? AppColors.primary
                                                  .withValues(alpha: 0.08)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'N°${serie.numero}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: isDone
                                                      ? AppColors.primary
                                                      : AppColors.text,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                '${serie.charge} kg',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                '${serie.repetitions} reps',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  // Edit set button
                                                  InkWell(
                                                    onTap: () =>
                                                        _editSet(index, sIndex),
                                                    child: const Padding(
                                                      padding:
                                                          EdgeInsets.all(4),
                                                      child: Icon(
                                                          Icons.edit_outlined,
                                                          size: 18,
                                                          color: AppColors
                                                              .textMuted),
                                                    ),
                                                  ),
                                                  // Delete set button
                                                  InkWell(
                                                    onTap: () =>
                                                        _removeSetFromExercise(
                                                            index, sIndex),
                                                    child: const Padding(
                                                      padding:
                                                          EdgeInsets.all(4),
                                                      child: Icon(
                                                          Icons.close_rounded,
                                                          size: 18,
                                                          color: AppColors
                                                              .textMuted),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  // Validate / Toggle completed set
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        if (isDone) {
                                                          _completedSets
                                                              .remove(setKey);
                                                        } else {
                                                          _completedSets
                                                              .add(setKey);
                                                          _startTimer(
                                                              item.tempsRepos,
                                                              exerciseName);
                                                        }
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration:
                                                          BoxDecoration(
                                                        color: isDone
                                                            ? AppColors.primary
                                                            : AppColors
                                                                .surface2,
                                                        shape: BoxShape.circle,
                                                        border: isDone
                                                            ? null
                                                            : Border.all(
                                                                color: AppColors
                                                                    .textMuted
                                                                    .withValues(
                                                                        alpha:
                                                                            0.3)),
                                                      ),
                                                      child: Icon(
                                                        Icons.check,
                                                        size: 18,
                                                        color: isDone
                                                            ? AppColors
                                                                .onPrimary
                                                            : AppColors
                                                                .textMuted,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                  const SizedBox(height: 12),
                                  // Button to add another set to this exercise
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        side: const BorderSide(
                                            color: AppColors.primary),
                                      ),
                                      onPressed: () => _addSetToExercise(
                                          index, exerciseName),
                                      icon: const Icon(Icons.add,
                                          size: 18, color: AppColors.primary),
                                      label: const Text(
                                        'Ajouter une série',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                      if (draft.exercices.isNotEmpty) ...[
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surface2,
                            foregroundColor: AppColors.text,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: _addExercise,
                          icon: const Icon(Icons.playlist_add),
                          label: const Text('Ajouter un autre exercice',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Final Workout Finish Action Button
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: draft.exercices.isEmpty ? null : _validate,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flag, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'VALIDER ET TERMINER LA SÉANCE',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Toutes les séries, charges et répétitions seront sauvegardées dans votre historique.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // --- Sticky Floating Timer Bar ---

  Widget _buildStickyFloatingTimerBar() {
    final progress = _timerDuration > 0
        ? (_timerRemaining / _timerDuration).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: AppColors.surface2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDuration(_timerRemaining),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timerIsRunning ? '⚡ REPOS EN COURS' : '⏸ EN PAUSE',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (_timerExerciseName != null)
                  Text(
                    _timerExerciseName!,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            onPressed: _timerIsRunning ? _pauseTimer : _resumeTimer,
            icon: Icon(
              _timerIsRunning ? Icons.pause_circle : Icons.play_circle,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            onPressed: () => _adjustTimer(30),
            icon: const Icon(Icons.add_alarm,
                color: AppColors.primary, size: 22),
            tooltip: '+30s',
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            onPressed: _resetTimer,
            icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }

  // --- Rest Timer Card Component (Petit Minuteur Detail) ---

  Widget _buildRestTimerCard() {
    final progress = _timerDuration > 0
        ? (_timerRemaining / _timerDuration).clamp(0.0, 1.0)
        : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'MINUTEUR DE REPOS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.8,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (_timerRemaining > 0)
                Text(
                  _timerIsRunning ? 'En cours...' : 'En pause',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _timerIsRunning
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Circular countdown visual
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: AppColors.surface2,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _formatDuration(_timerRemaining),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timerExerciseName != null
                          ? 'Repos : $_timerExerciseName'
                          : 'Temps de repos entre séries',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timerRemaining > 0
                          ? 'Objectif : ${_formatDuration(_timerDuration)} • Restant : ${_formatDuration(_timerRemaining)}'
                          : 'Sélectionnez un temps ou validez une série.',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Timer controls
          Row(
            children: [
              if (_timerRemaining > 0) ...[
                IconButton.filledTonal(
                  onPressed: _timerIsRunning ? _pauseTimer : _resumeTimer,
                  icon: Icon(_timerIsRunning ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 6),
                IconButton.outlined(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.replay),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () => _adjustTimer(-10),
                  child: const Text('-10s'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () => _adjustTimer(15),
                  child: const Text('+15s'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () => _adjustTimer(30),
                  child: const Text('+30s'),
                ),
              ] else ...[
                // Presets when timer is stopped
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [30, 45, 60, 90, 120, 180].map((sec) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('${sec}s'),
                            onPressed: () => _startTimer(sec, 'Repos rapide'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- Change Rest Time Dialog ---

  void _showChangeRestDialog(int exerciseIndex, int currentRest) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Temps de repos pour cet exercice'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [30, 45, 60, 90, 120, 180, 240, 300].map((sec) {
              final label = _formatDuration(sec);
              final isSelected = sec == currentRest;
              return ListTile(
                title: Text('$label ($sec secondes)'),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _updateExerciseRestTime(exerciseIndex, sec);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

// --- Add Exercise Dialog with multi-set & rest time config ---

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog({required this.exercises});

  final List<ExerciceModel> exercises;

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _repsController = TextEditingController(text: '10');
  final _chargeController = TextEditingController(text: '0');
  late String _selectedId;
  int _numberOfSets = 3;
  int _restSeconds = 60;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.exercises.isNotEmpty ? widget.exercises.first.id : '';
  }

  @override
  void dispose() {
    _repsController.dispose();
    _chargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return AlertDialog(
        title: const Text('Ajouter un exercice'),
        content: const Text('Aucun exercice disponible dans la base de données.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      );
    }

    // Ensure _selectedId matches an item in widget.exercises
    final validSelection = widget.exercises.any((e) => e.id == _selectedId)
        ? _selectedId
        : widget.exercises.first.id;

    return AlertDialog(
      title: const Text('Ajouter un exercice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: validSelection,
              decoration: const InputDecoration(
                labelText: 'Exercice',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              isExpanded: true,
              items: widget.exercises
                  .map((item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(
                          item.nameFr.isNotEmpty ? item.nameFr : item.id,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedId = value);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Répétitions',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _chargeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Charge (kg)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _numberOfSets,
              decoration: const InputDecoration(
                labelText: 'Nombre de séries',
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              items: [1, 2, 3, 4, 5, 6, 8, 10]
                  .map((count) => DropdownMenuItem<int>(
                        value: count,
                        child: Text('$count série${count > 1 ? 's' : ''}'),
                      ))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _numberOfSets = val ?? _numberOfSets),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _restSeconds,
              decoration: const InputDecoration(
                labelText: 'Temps de repos (secondes)',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              items: [30, 45, 60, 90, 120, 180, 240, 300]
                  .map((sec) => DropdownMenuItem<int>(
                        value: sec,
                        child: Text('${sec}s (${sec ~/ 60}m ${sec % 60}s)'),
                      ))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _restSeconds = val ?? _restSeconds),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final reps = int.tryParse(_repsController.text) ?? 10;
            final charge = double.tryParse(_chargeController.text) ?? 0.0;

            final seriesList = List.generate(
              _numberOfSets,
              (index) => SerieModel(
                numero: index + 1,
                repetitions: reps,
                charge: charge,
              ),
            );

            Navigator.pop(
              context,
              ExerciceSeanceModel(
                exerciceId: validSelection,
                series: seriesList,
                tempsRepos: _restSeconds,
              ),
            );
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

// --- Edit Exercise Dialog ---

class _EditExerciseDialog extends StatefulWidget {
  const _EditExerciseDialog({
    required this.exercises,
    required this.initialItem,
  });

  final List<ExerciceModel> exercises;
  final ExerciceSeanceModel initialItem;

  @override
  State<_EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<_EditExerciseDialog> {
  late String _selectedId;
  late int _restSeconds;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialItem.exerciceId;
    _restSeconds = widget.initialItem.tempsRepos;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return AlertDialog(
        title: const Text('Modifier l\'exercice'),
        content: const Text('Aucun exercice disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      );
    }

    final validSelection = widget.exercises.any((e) => e.id == _selectedId)
        ? _selectedId
        : (widget.exercises.any((e) => e.uuid == _selectedId)
            ? widget.exercises.firstWhere((e) => e.uuid == _selectedId).id
            : widget.exercises.first.id);

    return AlertDialog(
      title: const Text('Modifier l\'exercice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: validSelection,
              decoration: const InputDecoration(
                labelText: 'Changer l\'exercice',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              isExpanded: true,
              items: widget.exercises
                  .map((item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(
                          item.nameFr.isNotEmpty ? item.nameFr : item.id,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedId = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _restSeconds,
              decoration: const InputDecoration(
                labelText: 'Temps de repos (secondes)',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              items: [30, 45, 60, 90, 120, 180, 240, 300]
                  .map((sec) => DropdownMenuItem<int>(
                        value: sec,
                        child: Text('${sec}s (${sec ~/ 60}m ${sec % 60}s)'),
                      ))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _restSeconds = val ?? _restSeconds),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              ExerciceSeanceModel(
                exerciceId: validSelection,
                series: widget.initialItem.series,
                tempsRepos: _restSeconds,
              ),
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

// --- Edit Set Dialog ---

class _EditSetDialog extends StatefulWidget {
  const _EditSetDialog({
    required this.setNumber,
    required this.initialReps,
    required this.initialCharge,
  });

  final int setNumber;
  final int initialReps;
  final double initialCharge;

  @override
  State<_EditSetDialog> createState() => _EditSetDialogState();
}

class _EditSetDialogState extends State<_EditSetDialog> {
  late final TextEditingController _repsController;
  late final TextEditingController _chargeController;

  @override
  void initState() {
    super.initState();
    _repsController =
        TextEditingController(text: widget.initialReps.toString());
    _chargeController =
        TextEditingController(text: widget.initialCharge.toString());
  }

  @override
  void dispose() {
    _repsController.dispose();
    _chargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Modifier la série N°${widget.setNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _chargeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Charge (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Répétitions'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final reps = int.tryParse(_repsController.text) ?? widget.initialReps;
              final charge = double.tryParse(_chargeController.text) ?? widget.initialCharge;
              Navigator.pop(
                context,
                SerieModel(
                  numero: widget.setNumber,
                  repetitions: reps,
                  charge: charge,
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      );
}
