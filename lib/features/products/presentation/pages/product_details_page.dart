import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/di/injection.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/utils/formatters.dart';
import 'package:shopsphere/core/widgets/rating_stars.dart';
import 'package:shopsphere/core/widgets/shimmer_box.dart';
import 'package:shopsphere/core/widgets/state_views.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/presentation/bloc/product_details_cubit.dart';
import 'package:shopsphere/features/products/presentation/widgets/add_to_cart_bar.dart';
import 'package:shopsphere/features/products/presentation/widgets/image_carousel.dart';
import 'package:shopsphere/features/products/presentation/widgets/product_card.dart';
import 'package:shopsphere/features/products/presentation/widgets/review_tile.dart';

/// Full-screen details route used on compact / medium layouts.
class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({required this.productId, this.preview, super.key});

  final int productId;

  /// List item already on screen; used to render the hero image instantly.
  final Product? preview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: ProductDetailsView(productId: productId, preview: preview),
    );
  }
}

/// Details content; also embedded in the master–detail pane.
class ProductDetailsView extends StatelessWidget {
  const ProductDetailsView({
    required this.productId,
    this.preview,
    this.embedded = false,
    super.key,
  });

  final int productId;
  final Product? preview;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductDetailsCubit>()..load(productId),
      child: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
        builder: (context, state) => switch (state) {
          ProductDetailsLoading() => _DetailsSkeleton(preview: preview),
          ProductDetailsFailure(:final failure) => ErrorView(
            failure: failure is NotFoundFailure
                ? const NotFoundFailure(
                    'This product does not exist or was removed.',
                  )
                : failure,
            onRetry: context.read<ProductDetailsCubit>().retry,
            secondaryAction: !embedded && Navigator.of(context).canPop()
                ? OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to products'),
                  )
                : null,
          ),
          ProductDetailsLoaded(:final product) => _DetailsContent(
            product: product,
            embedded: embedded,
          ),
        },
      ),
    );
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({required this.product, required this.embedded});

  final Product product;

  /// In master–detail the list is on the same route, so no Hero here
  /// (duplicate tags in one route are not allowed).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Side-by-side gallery + info when there is room (landscape).
              final sideBySide =
                  constraints.maxWidth >= 720 &&
                  constraints.maxWidth > constraints.maxHeight;
              final gallery = ImageCarousel(
                images: product.gallery,
                heroTag: embedded ? null : productHeroTag(product.id),
                maxHeight: sideBySide
                    ? constraints.maxHeight - Spacing.xl
                    : 360,
              );
              final info = _Info(product: product);
              if (sideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.lg),
                        child: gallery,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(Spacing.lg),
                        child: info,
                      ),
                    ),
                  ],
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: Spacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        gallery,
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.lg,
                          ),
                          child: info,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Material(
          color: scheme.surfaceContainerLowest,
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: AddToCartBar(product: product),
            ),
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Spacing.lg),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (product.brand != null)
              _Pill(label: product.brand!, color: scheme.primary),
            _StockPill(product: product),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Text(product.title, style: text.headlineSmall),
        const SizedBox(height: Spacing.sm),
        RatingStars(rating: product.rating, showStars: true, size: 18),
        const SizedBox(height: Spacing.lg),
        Wrap(
          spacing: Spacing.sm,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(
              formatPrice(product.finalPrice),
              style: text.headlineMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (product.hasDiscount) ...[
              Text(
                formatPrice(product.price),
                style: text.titleMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              _Pill(
                label: '${product.discountPercentage.toStringAsFixed(1)}% off',
                color: AppColors.secondary,
              ),
            ],
          ],
        ),
        const SizedBox(height: Spacing.xl),
        Text('About this item', style: text.titleMedium),
        const SizedBox(height: Spacing.sm),
        Text(product.description, style: text.bodyLarge?.copyWith(height: 1.5)),
        if (product.shippingInformation != null ||
            product.warrantyInformation != null ||
            product.returnPolicy != null) ...[
          const SizedBox(height: Spacing.lg),
          Card(
            child: Column(
              children: [
                if (product.shippingInformation != null)
                  _InfoTile(
                    icon: Icons.local_shipping_outlined,
                    text: product.shippingInformation!,
                  ),
                if (product.warrantyInformation != null)
                  _InfoTile(
                    icon: Icons.verified_user_outlined,
                    text: product.warrantyInformation!,
                  ),
                if (product.returnPolicy != null)
                  _InfoTile(
                    icon: Icons.assignment_return_outlined,
                    text: product.returnPolicy!,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Spacing.xl),
        Text(
          'Customer reviews (${product.reviews.length})',
          style: text.titleMedium,
        ),
        const SizedBox(height: Spacing.sm),
        if (product.reviews.isEmpty)
          Text(
            'No reviews yet.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          for (final review in product.reviews) ReviewTile(review: review),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(text),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Spacing.md,
      vertical: Spacing.xs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
    ),
  );
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!product.isInStock) {
      return _Pill(label: 'Out of stock', color: scheme.error);
    }
    if (product.isLowStock) {
      return _Pill(
        label: 'Only ${product.stock} left',
        color: AppColors.warning,
      );
    }
    return _Pill(
      label: 'In stock (${product.stock})',
      color: AppColors.success,
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton({this.preview});

  final Product? preview;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (preview != null)
                ImageCarousel(
                  images: [preview!.thumbnail],
                  heroTag: productHeroTag(preview!.id),
                  maxHeight: 360,
                )
              else
                const SizedBox(height: 300, child: ShimmerBox(radius: 0)),
              const Padding(
                padding: EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 90, height: 24, radius: AppRadius.lg),
                    SizedBox(height: Spacing.md),
                    ShimmerBox(height: 26),
                    SizedBox(height: Spacing.sm),
                    ShimmerBox(width: 160, height: 18),
                    SizedBox(height: Spacing.lg),
                    ShimmerBox(width: 120, height: 32),
                    SizedBox(height: Spacing.xl),
                    ShimmerBox(height: 14),
                    SizedBox(height: Spacing.sm),
                    ShimmerBox(height: 14),
                    SizedBox(height: Spacing.sm),
                    ShimmerBox(width: 200, height: 14),
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
