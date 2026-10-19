import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/widgets/shimmer_box.dart';
import 'package:shopsphere/features/products/presentation/bloc/categories_cubit.dart';

/// Horizontally scrolling category filter. `null` = "All".
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.textScalerOf(context).scale(40) + 8;
    return SizedBox(
      height: height,
      child: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) {
          if (state.status == CategoriesStatus.loading) {
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
              itemBuilder: (_, _) => const Center(
                child: ShimmerBox(width: 84, height: 32, radius: AppRadius.lg),
              ),
            );
          }
          if (state.status == CategoriesStatus.failure) {
            return Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: context.read<CategoriesCubit>().load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Categories unavailable — retry'),
              ),
            );
          }
          final categories = state.categories;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
            itemBuilder: (context, index) {
              final slug = index == 0 ? null : categories[index - 1].slug;
              final label = index == 0 ? 'All' : categories[index - 1].name;
              final isSelected = slug == selected;
              return Center(
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => onSelected(slug),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
