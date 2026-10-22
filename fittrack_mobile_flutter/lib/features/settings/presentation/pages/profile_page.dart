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
  bool _isLoading = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _fill(UserModel? user) {
    if (_filled || user == null) return;
    _filled = true;
    _first.text = user.prenom ?? '';
    _last.text = user.nom ?? '';
    _weight.text = user.poids?.toString() ?? '';
    _height.text = user.taille?.toString() ?? '';
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final result = await ref.read(authProvider.notifier).updateProfile(
          prenom: _first.text.trim(),
          nom: _last.text.trim(),
          poids: double.tryParse(_weight.text),
          taille: double.tryParse(_height.text),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess && widget.forceComplete) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isSuccess
                ? '✨ Profil et historique mis à jour avec succès !'
                : result.failure!.message,
          ),
          backgroundColor: result.isSuccess ? Colors.green[800] : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  double? _calculateImc(double? weight, double? height) {
    if (weight == null || height == null || height <= 0) return null;
    final h = height > 3 ? height / 100 : height;
    return weight / (h * h);
  }

  Color _getImcColor(double imc) {
    if (imc < 18.5) return Colors.blueAccent;
    if (imc < 25) return AppColors.primary;
    if (imc < 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _getImcStatus(double imc) {
    if (imc < 18.5) return 'Insuffisance pondérale';
    if (imc < 25) return 'Poids optimal';
    if (imc < 30) return 'Surpoids';
    return 'Obésité';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    _fill(user);

    final currentWeight = double.tryParse(_weight.text) ?? user?.poids;
    final currentHeight = double.tryParse(_height.text) ?? user?.taille;
    final imc = _calculateImc(currentWeight, currentHeight);

    return AppShell(
      title: widget.forceComplete ? 'Compléter mon profil' : 'Mon profil',
      action: IconButton(
        onPressed: () => ref.read(authProvider.notifier).logout(),
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        tooltip: 'Se déconnecter',
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          120,
        ),
        children: [
          if (widget.forceComplete) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.secondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bienvenue ! Complète tes informations pour personnaliser ton expérience Kinetic Fit.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Profile Header Card with Gradient Accent
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surface2,
                  AppColors.surface1,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surface3),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          (user?.prenom?.isNotEmpty == true
                                  ? user!.prenom![0]
                                  : 'F')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                          ),
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
                                : 'Membre Fittrack',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'email@fittrack.com',
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppColors.surface3),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'IMC ACTUEL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            imc.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _getImcColor(imc),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 35,
                        width: 1,
                        color: AppColors.surface3,
                      ),
                      Column(
                        children: [
                          const Text(
                            'STATUT MÉTABOLIQUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getImcColor(imc).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              _getImcStatus(imc),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _getImcColor(imc),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Weight History Chart
          if (user != null) ...[
            const Text(
              'Évolution du poids',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            PoidsEvolutionGraphWidget(
              historiquePoids: user.historiquePoids.isNotEmpty
                  ? user.historiquePoids
                  : (user.poids != null
                      ? [
                          PoidsEntreeModel(
                              poids: user.poids!, date: DateTime.now())
                        ]
                      : const []),
            ),
            const SizedBox(height: 20),
          ],

          // Update Profile & Weight Form Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Informations personnelles & mesures',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _first,
                        style: const TextStyle(fontSize: 14), // Taille du texte saisi
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          labelStyle: TextStyle(fontSize: 13), // Taille du libellé (Prénom)
                          isDense: true, // Réduit le padding interne global du TextField
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 18, // Taille de l'icône réduite (par défaut c'est 24)
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _last,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          labelStyle: TextStyle(fontSize: 13), // Taille du libellé (Prénom)
                          isDense: true,
                          prefixIcon: Icon(Icons.badge_outlined,
                          size: 18,),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Poids (kg)',
                          labelStyle: TextStyle(fontSize: 13), // Taille du libellé (Prénom)
                          isDense: true,
                          prefixIcon: Icon(Icons.monitor_weight_outlined,
                          size: 18,),
                          hintText: 'ex: 75.5',
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
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Taille',
                          labelStyle: TextStyle(fontSize: 13), // Taille du libellé (Prénom)
                          isDense: true,
                          prefixIcon: Icon(Icons.height_rounded,
                          size: 18,),
                          hintText: '1.75 ou 175',
                          //helperText: 'en m ou cm',
                          //helperStyle: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _isLoading ? 'Enregistrement...' : 'Enregistrer les modifications',
                    icon: _isLoading ? null : Icons.save_rounded,
                    onPressed: _isLoading ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
