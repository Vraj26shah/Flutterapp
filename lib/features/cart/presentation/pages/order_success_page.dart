import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/utils/formatters.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';

/// Shown after `POST /carts/add` succeeds.
class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({required this.order, required this.total, super.key});

  final OrderConfirmation order;

  /// Grand total (after discount) as shown in the cart.
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      padding: const EdgeInsets.all(Spacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 72,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  Text(
                    'Order placed!',
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Thanks for shopping with ShopSphere.',
                    style: text.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.xl),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(
                        children: [
                          _Line('Order number', '#${order.orderId}'),
                          _Line(
                            'Items',
                            '${order.totalQuantity} '
                                '(${order.totalProducts} '
                                '${order.totalProducts == 1 ? 'product' : 'products'})',
                          ),
                          const Divider(height: Spacing.xl),
                          _Line('Order total', formatPrice(total), bold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Demo checkout — DummyJSON simulates the order.',
                    style: text.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Continue shopping'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
