import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(padding: padding, child: child),
      );
}

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.secondary = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: secondary ? AppColors.surface2 : AppColors.primary,
            foregroundColor: secondary ? AppColors.text : AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: onPressed,
          child: icon == null
              ? Text(label, style: const TextStyle(fontWeight: FontWeight.w700))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ],
                ),
        ),
      );
}

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, this.action, super.key});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 48, color: AppColors.tertiary),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
        label: Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white.withValues(alpha: .06),
        side: BorderSide.none,
      );
}

class AppError extends StatelessWidget {
  const AppError(this.message, {super.key, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(
        title: message,
        action: onRetry == null
            ? null
            : OutlinedButton(
                onPressed: onRetry, child: const Text('Réessayer')),
      );
}
