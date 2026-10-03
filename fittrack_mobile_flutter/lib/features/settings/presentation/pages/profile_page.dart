import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/widgets/app_shell.dart';

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
            result.isSuccess ? 'Profil enregistré' : result.failure!.message,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    _fill(auth.user);
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
          if (widget.forceComplete)
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.secondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complète ces informations pour accéder à ton espace.',
                    ),
                  ),
                ],
              ),
            ),
          if (widget.forceComplete) const SizedBox(height: 12),
          Text(auth.user?.email ?? '',
              style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _first,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _last,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Poids (kg)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _height,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Taille (m)'),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Enregistrer',
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
