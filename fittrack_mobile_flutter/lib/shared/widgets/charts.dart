import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

/// Kinetic Volt Weight Evolution Chart
class PoidsEvolutionGraphWidget extends StatelessWidget {
  const PoidsEvolutionGraphWidget({
    super.key,
    required this.historiquePoids,
    this.height = 200,
  });

  final List<PoidsEntreeModel> historiquePoids;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (historiquePoids.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, color: AppColors.textMuted, size: 36),
            SizedBox(height: 8),
            Text(
              'Aucun historique de poids enregistré',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final sortedList = List<PoidsEntreeModel>.from(historiquePoids)
      ..sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'ÉVOLUTION DU POIDS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${sortedList.last.poids} kg',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _KineticLineChartPainter(
                dataPoints: sortedList.map((e) => e.poids).toList(),
                lineColor: AppColors.primary,
                gradientColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sortedList.first.date != null
                    ? DateFormat('dd/MM').format(sortedList.first.date!)
                    : 'Début',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              Text(
                '${sortedList.length} pesée${sortedList.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
              ),
              Text(
                sortedList.last.date != null
                    ? DateFormat('dd/MM').format(sortedList.last.date!)
                    : 'Aujourd\'hui',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kinetic Volt Charge / Load Evolution Chart per Exercise or Volume
class ChargeEvolutionGraphWidget extends StatelessWidget {
  const ChargeEvolutionGraphWidget({
    super.key,
    required this.seances,
    this.exerciseNames = const {},
    this.height = 220,
  });

  final List<SeanceModel> seances;
  final Map<String, String> exerciseNames;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Collect validated sessions with max charges
    final validated = seances
        .where((s) => s.statut == 'validee')
        .toList()
      ..sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    final points = <_SessionLoadPoint>[];
    for (final s in validated) {
      double maxCharge = 0;
      for (final ex in s.exercices) {
        for (final serie in ex.series) {
          if (serie.charge > maxCharge) {
            maxCharge = serie.charge;
          }
        }
      }
      if (maxCharge > 0) {
        points.add(_SessionLoadPoint(date: s.date ?? DateTime.now(), maxCharge: maxCharge));
      }
    }

    if (points.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: AppColors.secondary, size: 36),
            SizedBox(height: 8),
            Text(
              'Aucune séance validée avec charge enregistrée',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Validez vos séances pour suivre l\'évolution de vos charges !',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final maxVal = points.map((p) => p.maxCharge).reduce(max);

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PROGRESSION DES CHARGES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MAX $maxVal kg',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _KineticLineChartPainter(
                dataPoints: points.map((p) => p.maxCharge).toList(),
                lineColor: AppColors.secondary,
                gradientColor: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM').format(points.first.date),
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              Text(
                '${points.length} séance${points.length > 1 ? 's' : ''} enregistrée${points.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('dd/MM').format(points.last.date),
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionLoadPoint {
  _SessionLoadPoint({required this.date, required this.maxCharge});
  final DateTime date;
  final double maxCharge;
}

class _KineticLineChartPainter extends CustomPainter {
  _KineticLineChartPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.gradientColor,
  });

  final List<double> dataPoints;
  final Color lineColor;
  final Color gradientColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final minVal = dataPoints.reduce(min);
    final maxVal = dataPoints.reduce(max);
    final valRange = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    // Padding
    final topPadding = 16.0;
    final bottomPadding = 16.0;
    final chartHeight = size.height - topPadding - bottomPadding;

    final points = <Offset>[];
    final stepX = dataPoints.length > 1
        ? size.width / (dataPoints.length - 1)
        : size.width / 2;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = dataPoints.length == 1 ? size.width / 2 : i * stepX;
      final normalizedY = (dataPoints[i] - minVal) / valRange;
      final y = size.height - bottomPadding - (normalizedY * chartHeight);
      points.add(Offset(x, y));
    }

    // Path for line
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final p1 = points[i - 1];
        final p2 = points[i];
        final controlP1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
        final controlP2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
        path.cubicTo(controlP1.dx, controlP1.dy, controlP2.dx, controlP2.dy, p2.dx, p2.dy);
      }
    }

    // Path for gradient fill
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.lineTo(points.first.dx, size.height);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        gradientColor.withValues(alpha: 0.25),
        gradientColor.withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Glow line
    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glowPaint);

    // Main line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw dots and text tags on data points
    final dotPaint = Paint()..color = lineColor;
    final innerDotPaint = Paint()..color = AppColors.surface1;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 2.5, innerDotPaint);

      // Draw value text for min, max, or last
      if (i == points.length - 1 || dataPoints[i] == maxVal || dataPoints[i] == minVal) {
        final textSpan = TextSpan(
          text: '${dataPoints[i]}',
          style: TextStyle(
            color: lineColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        final textOffset = Offset(
          (pt.dx - textPainter.width / 2).clamp(0, size.width - textPainter.width),
          pt.dy - 18,
        );
        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KineticLineChartPainter oldDelegate) => true;
}
