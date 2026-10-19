import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';

/// Thin animated banner shown when the device has no connectivity.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.isOffline, super.key});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: isOffline
          ? Material(
              color: scheme.inverseSurface,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 18,
                        color: scheme.onInverseSurface,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          'You are offline — showing saved data',
                          style: TextStyle(color: scheme.onInverseSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
