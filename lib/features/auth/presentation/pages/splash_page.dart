import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/features/auth/presentation/widgets/brand_logo.dart';

/// Shown while AuthBloc checks for a stored session.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: const BrandLogo(size: 88, onDark: true),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'ShopSphere',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Spacing.xxl),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: scheme.onPrimary.withValues(alpha: 0.8),
                semanticsLabel: 'Checking your session',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
