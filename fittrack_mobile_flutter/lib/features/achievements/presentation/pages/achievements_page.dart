import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';

class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _calculateWorkoutVolume(SeanceModel workout) {
    double total = 0;
    for (final ex in workout.exercices) {
      for (final set in ex.series) {
        total += (set.charge * set.repetitions);
      }
    }
    return total;
  }

  int _calculateWorkoutSets(SeanceModel workout) {
    int count = 0;
    for (final ex in workout.exercices) {
      count += ex.series.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final workoutsAsync = ref.watch(workoutsProvider);

    return AppShell(
      title: 'Performance & Succès',
      child: Column(
        children: [
          // Segmented Tab Navigation
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.onPrimary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Graphes'),
                Tab(text: 'Historique'),
                Tab(text: 'Succès'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Performances & Graphs
                _buildPerformanceTab(workoutsAsync),

                // TAB 2: Workout History
                _buildHistoryTab(workoutsAsync),

                // TAB 3: Achievements list
                _buildAchievementsTab(achievementsAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: Performance Stats & Graphs ---

  Widget _buildPerformanceTab(AsyncValue<List<SeanceModel>> workoutsAsync) {
    return workoutsAsync.when(
      loading: () => const AppLoader(),
      error: (error, _) => AppError(
        failureMessage(error),
        onRetry: () => ref.invalidate(workoutsProvider),
      ),
      data: (workouts) {
        final validatedWorkouts =
            workouts.where((w) => w.statut == 'validee').toList();

        double totalVolumeAllTime = 0;
        int totalSetsAllTime = 0;
        for (final w in validatedWorkouts) {
          totalVolumeAllTime += _calculateWorkoutVolume(w);
          totalSetsAllTime += _calculateWorkoutSets(w);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            100,
          ),
          children: [
            // Performance Summary Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Séances\n',
                    value: '${validatedWorkouts.length}',
                    subtitle: 'Validées',
                    icon: Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: 'Volume \n''total',
                    value: totalVolumeAllTime >= 1000
                        ? '${(totalVolumeAllTime / 1000).toStringAsFixed(1)} t'
                        : '${totalVolumeAllTime.toInt()} kg',
                    subtitle: 'Cumulé',
                    icon: Icons.fitness_center_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: 'Séries\n',
                    value: '$totalSetsAllTime',
                    subtitle: 'Effectuées',
                    icon: Icons.repeat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Performance Line Graph
            _VolumeTrendChart(workouts: validatedWorkouts),
            const SizedBox(height: 16),

            // Recent Milestones Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emoji_events,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Résumé des performances',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    label: 'Moyenne de séries par séance',
                    value: validatedWorkouts.isNotEmpty
                        ? (totalSetsAllTime / validatedWorkouts.length)
                            .toStringAsFixed(1)
                        : '0',
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    label: 'Volume moyen par séance',
                    value: validatedWorkouts.isNotEmpty
                        ? '${(totalVolumeAllTime / validatedWorkouts.length).toStringAsFixed(0)} kg'
                        : '0 kg',
                  ),
                  // const Divider(height: 16),
                  // _buildSummaryRow(
                  //   label: 'Statut de synchronisation',
                  //   value: 'En direct avec l\'API',
                  // ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
              Icon(icon, size: 14, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // --- TAB 2: Workout History ---

  Widget _buildHistoryTab(AsyncValue<List<SeanceModel>> workoutsAsync) {
    return workoutsAsync.when(
      loading: () => const AppLoader(),
      error: (error, _) => AppError(
        failureMessage(error),
        onRetry: () => ref.invalidate(workoutsProvider),
      ),
      data: (workouts) {
        final validated =
            workouts.where((w) => w.statut == 'validee').toList();

        if (validated.isEmpty) {
          return const EmptyState(
            title: 'Aucune séance validée pour le moment.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            100,
          ),
          itemCount: validated.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final workout = validated[index];
            final volume = _calculateWorkoutVolume(workout);
            final setsCount = _calculateWorkoutSets(workout);

            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            workout.valideeLe != null
                                ? DateFormat('EEEE dd/MM/yyyy', 'fr')
                                    .format(workout.valideeLe!)
                                : (workout.date != null
                                    ? DateFormat('EEEE dd/MM/yyyy', 'fr')
                                        .format(workout.date!)
                                    : 'Séance validée'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      StatusChip(workout.statut),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exercices',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${workout.exercices.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Séries totales',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$setsCount',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Volume Séance',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${volume.toInt()} kg',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 3: Achievements List ---

  Widget _buildAchievementsTab(
      AsyncValue<List<SuccesModel>> achievementsAsync) {
    return achievementsAsync.when(
      loading: () => const AppLoader(),
      error: (error, _) => AppError(
        failureMessage(error),
        onRetry: () => ref.invalidate(achievementsProvider),
      ),
      data: (achievements) => achievements.isEmpty
          ? const EmptyState(title: 'Tes succès apparaîtront ici après validation.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                100,
              ),
              itemCount: achievements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final achievement = achievements[index];
                return AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events,
                          color: AppColors.primary, size: 18),
                    ),
                    title: Text(
                      achievement.description,
                      style: const TextStyle(
                        fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      achievement.dateObtention == null
                          ? 'Débloqué lors de votre entraînement'
                          : DateFormat('dd MMMM yyyy', 'fr')
                              .format(achievement.dateObtention!),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// --- Custom Painted Performance Line Chart ---

class _VolumeTrendChart extends StatelessWidget {
  const _VolumeTrendChart({required this.workouts});

  final List<SeanceModel> workouts;

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return AppCard(
        child: Container(
          height: 160,
          alignment: Alignment.center,
          child: const Text(
            'Validez vos séances pour afficher votre courbe de progression.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final sorted = List<SeanceModel>.from(workouts)
      ..sort((a, b) =>
          (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    final recent =
        sorted.length > 8 ? sorted.sublist(sorted.length - 8) : sorted;

    final volumes = recent.map((w) {
      double vol = 0;
      for (final ex in w.exercices) {
        for (final s in ex.series) {
          vol += (s.charge * s.repetitions);
        }
      }
      return vol;
    }).toList();

    final maxVolume = volumes.fold<double>(0, (prev, curr) => max(prev, curr));
    final chartMax = maxVolume == 0 ? 100.0 : maxVolume * 1.25;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Progression du volume (kg)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                '${recent.length} séance${recent.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(
                volumes: volumes,
                dates: recent.map((w) => w.date ?? DateTime.now()).toList(),
                maxVolume: chartMax,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.volumes,
    required this.dates,
    required this.maxVolume,
  });

  final List<double> volumes;
  final List<DateTime> dates;
  final double maxVolume;

  @override
  void paint(Canvas canvas, Size size) {
    if (volumes.isEmpty) return;

    final paddingBottom = 24.0;
    final paddingTop = 12.0;
    final chartHeight = size.height - paddingBottom - paddingTop;
    final chartWidth = size.width;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.surface3.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final points = <Offset>[];
    final stepX =
        volumes.length > 1 ? chartWidth / (volumes.length - 1) : chartWidth / 2;

    for (int i = 0; i < volumes.length; i++) {
      final x = volumes.length > 1 ? i * stepX : chartWidth / 2;
      final y =
          paddingTop + chartHeight * (1.0 - (volumes[i] / maxVolume));
      points.add(Offset(x, y));
    }

    // Gradient Fill under curve
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, size.height - paddingBottom);
      for (final p in points) {
        path.lineTo(p.dx, p.dy);
      }
      path.lineTo(points.last.dx, size.height - paddingBottom);
      path.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromLTWH(0, paddingTop, chartWidth, chartHeight));

      canvas.drawPath(path, fillPaint);
    }

    // Line Path
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        linePath.moveTo(points[i].dx, points[i].dy);
      } else {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Data points & Text Labels
    final pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final pointInnerPaint = Paint()
      ..color = AppColors.canvas
      ..style = PaintingStyle.fill;

    final textStyle = const TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    final valueStyle = const TextStyle(
      color: AppColors.text,
      fontSize: 10,
      fontWeight: FontWeight.w900,
    );

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 6, pointPaint);
      canvas.drawCircle(p, 3, pointInnerPaint);

      // Date label at bottom
      final dateText = DateFormat('dd/MM').format(dates[i]);
      final textSpan = TextSpan(text: dateText, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final textX = (p.dx - textPainter.width / 2)
          .clamp(0.0, chartWidth - textPainter.width);
      textPainter.paint(
          canvas, Offset(textX, size.height - paddingBottom + 6));

      // Value label above point
      final valText = '${volumes[i].toInt()}k';
      final valSpan = TextSpan(text: valText, style: valueStyle);
      final valPainter = TextPainter(
        text: valSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final valX = (p.dx - valPainter.width / 2)
          .clamp(0.0, chartWidth - valPainter.width);
      final valY = max(0.0, p.dy - 16);
      valPainter.paint(canvas, Offset(valX, valY));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
