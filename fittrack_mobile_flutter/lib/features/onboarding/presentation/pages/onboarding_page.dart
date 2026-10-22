import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      icon: Icons.fitness_center_rounded,
      accentColor: AppColors.primary,
      title: 'Des programmes\nsur-mesure',
      description:
          'Crée tes propres routines d\'entraînement, suis tes séries, charges et temps de repos avec une précision maximale.',
    ),
    _OnboardingItem(
      icon: Icons.insights_rounded,
      accentColor: AppColors.secondary,
      title: 'Analyse détaillée de\nta progression',
      description:
          'Visualise l\'évolution de ton volume de travail, ton suivi de poids et ta régularité grâce à des graphiques dynamiques.',
    ),
    _OnboardingItem(
      icon: Icons.emoji_events_rounded,
      accentColor: AppColors.primary,
      title: 'Atteins tes objectifs\net gagne des trophées',
      description:
          'Fixe tes cibles personnalisées, franchis de nouveaux paliers et débloque des succès motivants à chaque séance.',
    ),
  ];

  Future<void> _finishOnboarding() async {
    final router = GoRouter.of(context);
    await ref.read(storageProvider).setHasSeenOnboarding(true);
    router.go('/register');
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Header bar: Logo + Title + Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/logofit.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primary,
                            child: const Icon(Icons.bolt,
                                color: AppColors.onPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'FITTRACK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'Passer',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Onboarding PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hero Icon Badge
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.accentColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: item.accentColor.withValues(alpha: 0.15),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            size: 56,
                            color: item.accentColor,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation: Page Indicators & Action Buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.surface3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _nextPage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _items.length - 1
                                ? 'C\'est parti !'
                                : 'Suivant',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _items.length - 1
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option to directly sign in
                  if (_currentPage == _items.length - 1)
                    TextButton(
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        await ref.read(storageProvider).setHasSeenOnboarding(true);
                        router.go('/login');
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: 'Déjà un compte ? ',
                          style: TextStyle(color: AppColors.textMuted),
                          children: [
                            TextSpan(
                              text: 'Se connecter',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
}
