import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/utils/formatters.dart';
import 'package:shopsphere/core/widgets/rating_stars.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({required this.review, super.key});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = review.reviewerName.isEmpty
        ? '?'
        : review.reviewerName[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                child: Text(initial),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Spacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          review.reviewerName,
                          style: theme.textTheme.titleSmall,
                        ),
                        if (review.date != null)
                          Text(
                            formatDate(review.date!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    RatingStars(
                      rating: review.rating.toDouble(),
                      showStars: true,
                      size: 14,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(review.comment, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
