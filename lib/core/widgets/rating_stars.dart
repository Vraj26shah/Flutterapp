import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';

/// Compact "★ 4.5" rating label (or full 5-star row with [showStars]).
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    this.showStars = false,
    this.size = 16,
    super.key,
  });

  final double rating;
  final bool showStars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Semantics(
      label: 'Rated ${rating.toStringAsFixed(1)} out of 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStars)
            for (var i = 1; i <= 5; i++)
              Icon(
                rating >= i
                    ? Icons.star_rounded
                    : rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
                size: size,
                color: AppColors.rating,
              )
          else
            Icon(Icons.star_rounded, size: size, color: AppColors.rating),
          const SizedBox(width: Spacing.xs),
          Text(rating.toStringAsFixed(1), style: style),
        ],
      ),
    );
  }
}
