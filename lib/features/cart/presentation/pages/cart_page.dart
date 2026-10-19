import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/utils/formatters.dart';
import 'package:shopsphere/core/widgets/app_network_image.dart';
import 'package:shopsphere/core/widgets/state_views.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';
import 'package:shopsphere/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:shopsphere/features/cart/presentation/pages/order_success_page.dart';
import 'package:shopsphere/features/cart/presentation/widgets/quantity_stepper.dart';

class CartPage extends StatelessWidget {
  const CartPage({this.onBrowse, super.key});

  /// Switches the shell to the products tab.
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listenWhen: (p, c) => p.checkoutStatus != c.checkoutStatus,
      listener: (context, state) async {
        if (state.checkoutStatus == CheckoutStatus.success &&
            state.order != null) {
          final bloc = context.read<CartBloc>();
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => OrderSuccessPage(
                order: state.order!,
                total: state.lastOrderTotal,
              ),
            ),
          );
          bloc.add(const CartCheckoutAcknowledged());
        } else if (state.checkoutStatus == CheckoutStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.failure?.message ?? 'Could not place the order.',
              ),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () =>
                    context.read<CartBloc>().add(const CartCheckoutRequested()),
              ),
            ),
          );
          context.read<CartBloc>().add(const CartCheckoutAcknowledged());
        }
      },
      builder: (context, state) {
        if (!state.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.isEmpty) {
          return EmptyView(
            icon: Icons.shopping_cart_outlined,
            title: 'Your cart is empty',
            message: 'Products you add will show up here.',
            action: onBrowse == null
                ? null
                : FilledButton.icon(
                    onPressed: onBrowse,
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Start shopping'),
                  ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final list = _CartList(items: state.items);
            final summary = _Summary(state: state);
            if (constraints.maxWidth >= 840) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: list),
                  SizedBox(
                    width: 360,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: summary,
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Expanded(child: list),
                Material(
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: summary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CartList extends StatelessWidget {
  const _CartList({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.productId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: Spacing.xl),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          onDismissed: (_) => _remove(context, item),
          child: _CartTile(item: item),
        );
      },
    );
  }
}

void _remove(BuildContext context, CartItem item) {
  final bloc = context.read<CartBloc>()..add(CartItemRemoved(item.productId));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Removed ${item.title}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => bloc.add(CartItemAdded(item)),
        ),
      ),
    );
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox.square(
                dimension: 84,
                child: ColoredBox(
                  color: scheme.surfaceContainerLow,
                  child: AppNetworkImage(
                    url: item.thumbnail,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove ${item.title}',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _remove(context, item),
                      ),
                    ],
                  ),
                  Text(
                    '${formatPrice(item.price)} each'
                    '${item.discountPercentage > 0 ? ' · ${item.discountPercentage.toStringAsFixed(0)}% off' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.md,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      QuantityStepper(
                        quantity: item.quantity,
                        max: item.stock,
                        compact: true,
                        onChanged: (q) => context.read<CartBloc>().add(
                          CartQuantityChanged(item.productId, q),
                        ),
                      ),
                      Text(
                        formatPrice(item.lineTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = state.totals;
    final submitting = state.checkoutStatus == CheckoutStatus.submitting;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          label:
              'Subtotal (${totals.itemCount} '
              '${totals.itemCount == 1 ? 'item' : 'items'})',
          value: formatPrice(totals.subtotal),
        ),
        const SizedBox(height: Spacing.xs),
        _Row(
          label: 'Discount',
          value: '−${formatPrice(totals.discount)}',
          valueColor: AppColors.success,
        ),
        const Divider(height: Spacing.xl),
        _Row(
          label: 'Total',
          value: formatPrice(totals.total),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: Spacing.lg),
        FilledButton(
          onPressed: submitting
              ? null
              : () =>
                    context.read<CartBloc>().add(const CartCheckoutRequested()),
          child: submitting
              ? SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.onPrimary,
                    semanticsLabel: 'Placing order',
                  ),
                )
              : const Text('Place order'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.style,
    this.valueColor,
  });

  final String label;
  final String value;
  final TextStyle? style;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge;
    return Row(
      children: [
        Expanded(child: Text(label, style: base)),
        Text(
          value,
          style: base?.copyWith(color: valueColor, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
