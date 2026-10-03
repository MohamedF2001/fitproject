import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/charts.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, this.forceComplete = false});
  final bool forceComplete;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _fill(UserModel? user) {
    if (_filled) return;
    _filled = true;
    _first.text = user?.prenom ?? '';
    _last.text = user?.nom ?? '';
    _weight.text = user?.poids?.toString() ?? '';
    _height.text = user?.taille?.toString() ?? '';
  }

  Future<void> _save() async {
    final result = await ref.read(authProvider.notifier).updateProfile(
          prenom: _first.text.trim(),
          nom: _last.text.trim(),
          poids: double.tryParse(_weight.text),
          taille: double.tryParse(_height.text),
        );
    if (!mounted) return;
    if (result.isSuccess && widget.forceComplete) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isSuccess ? 'Profil et historique du poids enregistrés' : result.failure!.message,
          ),
        ),
      );
    }
  }

  double? _calculateImc(double? weight, double? height) {
    if (weight == null || height == null || height <= 0) return null;
    // convert cm to m if needed
    final h = height > 3 ? height / 100 : height;
    return weight / (h * h);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    _fill(user);

    final imc = _calculateImc(
      double.tryParse(_weight.text) ?? user?.poids,
      double.tryParse(_height.text) ?? user?.taille,
    );

    return AppShell(
      title: widget.forceComplete ? 'Compléter mon profil' : 'Mon profil',
      action: IconButton(
        onPressed: () => ref.read(authProvider.notifier).logout(),
        icon: const Icon(Icons.logout),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          100,
        ),
        children: [
          if (widget.forceComplete) ...[
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.secondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complète ces informations pour accéder à ton espace Kinetic Fit.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Profile Header Card
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        (user?.prenom?.isNotEmpty == true
                                ? user!.prenom![0]
                                : 'F')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim().isNotEmpty
                                ? '${user?.prenom ?? ''} ${user?.nom ?? ''}'
                                : 'Membre FitTrack',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (imc != null) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('IMC CALCULÉ',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            imc.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('STATUT METABOLIQUE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            imc < 18.5
                                ? 'Poids léger'
                                : imc < 25
                                    ? 'Poids optimal'
                                    : imc < 30
                                        ? 'Surpoids'
                                        : 'Masse élevée',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Weight History Chart
          if (user != null)
            PoidsEvolutionGraphWidget(
              historiquePoids: user.historiquePoids.isNotEmpty
                  ? user.historiquePoids
                  : (user.poids != null
                      ? [PoidsEntreeModel(poids: user.poids!, date: DateTime.now())]
                      : const []),
            ),

          const SizedBox(height: 16),

          // Update Profile & Weight Form Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'METTRE À JOUR MES MESURES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _first,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _last,
                        decoration: const InputDecoration(labelText: 'Nom'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Poids actuel (kg)',
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _height,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Taille (m)',
                          prefixIcon: Icon(Icons.height),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Enregistrer mon poids et profil',
                  icon: Icons.check,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
