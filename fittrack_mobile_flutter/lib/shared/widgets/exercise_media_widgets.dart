import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fittrack_mobile_flutter/core/theme/app_theme.dart';
import 'package:fittrack_mobile_flutter/features/exercises/domain/exercise_media.dart';

/// Miniature d'exercice affichant la première photo ou une icône de remplacement.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb({
    super.key,
    required this.exerciseId,
    this.size = 48.0,
  });

  final String exerciseId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final paths = ExerciseMedia.pathsFor(exerciseId);

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.fitness_center,
          color: AppColors.textMuted,
          size: size * 0.5,
        ),
      );
    }

    if (paths.isEmpty) return fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        paths.first,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }
}

/// DÉMO d'exercice alternant doucement les deux photos de mouvements.
class ExerciseDemo extends StatefulWidget {
  const ExerciseDemo({
    super.key,
    required this.exerciseId,
    this.height = 160.0,
  });

  final String exerciseId;
  final double height;

  @override
  State<ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<ExerciseDemo> {
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant ExerciseDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseId != widget.exerciseId) {
      _currentIndex = 0;
      _startAnimation();
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    final paths = ExerciseMedia.pathsFor(widget.exerciseId);
    if (paths.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
        if (!mounted) return;
        setState(() {
          _currentIndex = (_currentIndex + 1) % paths.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paths = ExerciseMedia.pathsFor(widget.exerciseId);

    Widget fallback() {
      return Container(
        width: double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.fitness_center,
            color: AppColors.textMuted,
            size: 48,
          ),
        ),
      );
    }

    if (paths.isEmpty) return fallback();

    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final path = disableAnimations || paths.length <= 1
        ? paths.first
        : paths[_currentIndex % paths.length];

    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Image.asset(
          path,
          key: ValueKey(path),
          width: double.infinity,
          height: widget.height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      ),
    );
  }
}
