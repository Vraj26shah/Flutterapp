import 'package:flutter/material.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/theme/app_theme.dart';

/// Shared layout for full-screen informational states.
class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.xl),
                decoration: BoxDecoration(
                  color: (iconColor ?? scheme.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: iconColor ?? scheme.primary),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (message != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: Spacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly error state with an optional Retry action. Never shows raw
/// stack traces — only the [Failure]'s user-facing message.
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.failure,
    this.onRetry,
    this.secondaryAction,
    super.key,
  });

  final Failure failure;
  final VoidCallback? onRetry;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final (icon, title) = switch (failure) {
      NetworkFailure() => (Icons.wifi_off_rounded, 'You are offline'),
      TimeoutFailure() => (Icons.hourglass_bottom_rounded, 'Taking too long'),
      NotFoundFailure() => (Icons.search_off_rounded, 'Not found'),
      UnauthorizedFailure() => (Icons.lock_clock_rounded, 'Session expired'),
      _ => (Icons.cloud_off_rounded, 'Something went wrong'),
    };
    final showRetry = onRetry != null && failure.isRetryable;
    return _StateView(
      icon: icon,
      title: title,
      message: failure.message,
      iconColor: Theme.of(context).colorScheme.error,
      action: (showRetry || secondaryAction != null)
          ? Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.md,
              alignment: WrapAlignment.center,
              children: [
                if (showRetry)
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ?secondaryAction,
              ],
            )
          : null,
    );
  }
}

/// Empty state (no results, empty cart, …).
class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      _StateView(icon: icon, title: title, message: message, action: action);
}
