import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/utils/formatters.dart';
import 'package:shopsphere/core/widgets/app_network_image.dart';
import 'package:shopsphere/core/widgets/rating_stars.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';

/// Hero tag shared by the list thumbnail and the details carousel.
String productHeroTag(int id) => 'product-image-$id';

/// Height of the text block below the image, before text scaling.
const productCardInfoHeight = 112.0;

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  final Product product;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${product.title}, ${formatPrice(product.finalPrice)}'
          '${product.isInStock ? '' : ', out of stock'}',
      excludeSemantics: true,
      child: Card(
        shape: isSelected
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: scheme.primary, width: 2),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: scheme.surfaceContainerLow,
                      child: Hero(
                        tag: productHeroTag(product.id),
                        child: AppNetworkImage(
                          url: product.thumbnail,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (product.hasDiscount && product.isInStock)
                      Positioned(
                        top: Spacing.sm,
                        left: Spacing.sm,
                        child: _Badge(
                          label:
                              '-${product.discountPercentage.toStringAsFixed(0)}%',
                          color: AppColors.secondary,
                        ),
                      ),
                    if (!product.isInStock)
                      ColoredBox(
                        color: scheme.surface.withValues(alpha: 0.6),
                        child: Center(
                          child: _Badge(
                            label: 'Out of stock',
                            color: scheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.sm,
                    Spacing.md,
                    Spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand ?? _titleCase(product.category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(height: 1.25),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              formatPrice(product.finalPrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: Spacing.xs),
                            Flexible(
                              child: Text(
                                formatPrice(product.price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      RatingStars(rating: product.rating, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _titleCase(String slug) => slug
    .split('-')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}
