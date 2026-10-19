import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';

/// `[-] 2 [+]` control with 48dp tap targets.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.enabled = true,
    this.compact = false,
    super.key,
  });

  final int quantity;
  final int min;
  final int max;
  final bool enabled;
  final bool compact;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canDecrement = enabled && quantity > min;
    final canIncrement = enabled && quantity < max;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease quantity',
            onPressed: canDecrement ? () => onChanged(quantity - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: compact ? 20 : 28),
            child: Semantics(
              label: 'Quantity $quantity',
              excludeSemantics: true,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            onPressed: canIncrement ? () => onChanged(quantity + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
