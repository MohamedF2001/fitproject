import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';

class _FormPage extends ConsumerStatefulWidget {
  const _FormPage({required this.register});
  final bool register;

  @override
  ConsumerState<_FormPage> createState() => _FormPageState();
}

class _FormPageState extends ConsumerState<_FormPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final auth = ref.read(authProvider.notifier);
    final result = widget.register
        ? await auth.register(_email.text.trim(), _password.text)
        : await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isSuccess) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: AppColors.primary,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.register
                            ? 'Crée ton espace athlète'
                            : 'Content de te revoir',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.register
                            ? 'Ton entraînement, tes objectifs, ton rythme.'
                            : 'Prêt à reprendre là où tu t’es arrêté ?',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 28),
                      AppCard(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Adresse email',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: (value) =>
                                  value != null && value.contains('@')
                                      ? null
                                      : 'Adresse email invalide',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) =>
                                  value != null && value.length >= 6
                                      ? null
                                      : '6 caractères minimum',
                            ),
                            const SizedBox(height: 20),
                            AppButton(
                              label: widget.register
                                  ? 'Créer mon compte'
                                  : 'Se connecter',
                              icon: Icons.arrow_forward,
                              onPressed: _busy ? null : _submit,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => context.go(
                                    widget.register ? '/login' : '/register',
                                  ),
                          child: Text(
                            widget.register
                                ? 'J’ai déjà un compte'
                                : 'Créer un compte',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => const _FormPage(register: false);
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override
  Widget build(BuildContext context) => const _FormPage(register: true);
}
