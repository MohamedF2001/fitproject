import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({required this.achievements, super.key});
  final List<SuccesModel> achievements;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .25),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check,
                        color: AppColors.onPrimary, size: 54),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Séance validée !',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bravo pour le travail accompli.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  if (achievements.isNotEmpty)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Succès débloqué',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          for (final achievement in achievements)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(achievement.description),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Retour à l’accueil',
                    icon: Icons.arrow_forward,
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/achievements'),
                    child: const Text('Voir mes succès'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
