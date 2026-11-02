import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final minDelay = Future.delayed(const Duration(seconds: 2));

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      // Toujours vérifier auprès du serveur si l'utilisateur est réellement connecté
      await ref.read(authProvider.notifier).refreshProfile();
    }

    await minDelay;
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final updatedAuth = ref.read(authProvider);
    final storage = ref.read(storageProvider);

    if (updatedAuth.isAuthenticated) {
      if (updatedAuth.user?.isComplete == true) {
        context.go('/home');
      } else {
        context.go('/complete-profile');
      }
    } else if (!storage.hasSeenOnboarding) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: SizedBox(
          width: screenWidth * 0.7,
          child: Image.asset(
            'assets/images/mongif.gif',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
