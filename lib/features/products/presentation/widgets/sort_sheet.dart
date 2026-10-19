import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';

/// Bottom sheet listing sort options; returns the chosen [ProductSort].
Future<ProductSort?> showSortSheet(BuildContext context, ProductSort current) {
  return showModalBottomSheet<ProductSort>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xl,
                0,
                Spacing.xl,
                Spacing.sm,
              ),
              child: Text(
                'Sort by',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final sort in ProductSort.values)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.xl,
                ),
                title: Text(sort.label),
                selected: sort == current,
                trailing: sort == current
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(sort),
              ),
            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    ),
  );
}
