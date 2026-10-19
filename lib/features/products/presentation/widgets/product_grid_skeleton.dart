import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/widgets/shimmer_box.dart';

/// Shimmer placeholder card matching [ProductCard]'s layout.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 1, child: ShimmerBox(radius: 0)),
          Padding(
            padding: EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 60, height: 10),
                SizedBox(height: Spacing.sm),
                ShimmerBox(height: 14),
                SizedBox(height: Spacing.xs),
                ShimmerBox(width: 100, height: 14),
                SizedBox(height: Spacing.md),
                ShimmerBox(width: 70, height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
