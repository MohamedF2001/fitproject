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
  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Afficher le GIF pendant 3 secondes puis naviguer
    _navigationTimer = Timer(const Duration(seconds: 8), () {
      _navigateToNext();
    });
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _navigationTimer?.cancel();

    final auth = ref.read(authProvider);
    final storage = ref.read(storageProvider);

    if (auth.isAuthenticated) {
      if (auth.user?.isComplete == true) {
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
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black26.withValues(alpha: 8.5),
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
