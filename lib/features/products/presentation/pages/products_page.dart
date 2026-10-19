import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/network/connectivity_cubit.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/utils/breakpoints.dart';
import 'package:shopsphere/core/utils/debouncer.dart';
import 'package:shopsphere/core/widgets/state_views.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/presentation/bloc/categories_cubit.dart';
import 'package:shopsphere/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:shopsphere/features/products/presentation/pages/product_details_page.dart';
import 'package:shopsphere/features/products/presentation/widgets/category_chips.dart';
import 'package:shopsphere/features/products/presentation/widgets/product_card.dart';
import 'package:shopsphere/features/products/presentation/widgets/product_grid_skeleton.dart';
import 'package:shopsphere/features/products/presentation/widgets/sort_sheet.dart';

/// Home tab. Grid on phones/tablets; master–detail when expanded (> 1024dp).
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  /// Selected product in master–detail mode (pure UI state).
  int? _selectedId;

  void _open(BuildContext context, Product product, WindowSize size) {
    if (size.isExpanded) {
      setState(() => _selectedId = product.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ProductDetailsPage(productId: product.id, preview: product),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, bool>(
      // Back online after a failed load → retry automatically.
      listener: (context, isOffline) {
        final bloc = context.read<ProductListBloc>();
        if (!isOffline &&
            (bloc.state.status == ProductListStatus.failure ||
                bloc.state.isFromCache)) {
          bloc.add(const ProductsFetched());
          context.read<CategoriesCubit>().load();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = WindowSize.of(MediaQuery.sizeOf(context).width);
          final catalog = _Catalog(
            selectedId: size.isExpanded ? _selectedId : null,
            onOpen: (p) => _open(context, p, size),
          );
          if (!size.isExpanded) return catalog;
          return Row(
            children: [
              Expanded(flex: 5, child: catalog),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 4,
                child: _selectedId == null
                    ? const EmptyView(
                        icon: Icons.touch_app_outlined,
                        title: 'Select a product',
                        message: 'Product details will appear here.',
                      )
                    : ProductDetailsView(
                        key: ValueKey(_selectedId),
                        productId: _selectedId!,
                        embedded: true,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Catalog extends StatefulWidget {
  const _Catalog({required this.onOpen, this.selectedId});

  final ValueChanged<Product> onOpen;
  final int? selectedId;

  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _search.text = context.read<ProductListBloc>().state.query.search;
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      context.read<ProductListBloc>().add(const ProductsNextPageRequested());
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // toggles the clear button
    _debouncer.run(() {
      if (mounted) {
        context.read<ProductListBloc>().add(ProductsSearchChanged(value));
      }
    });
  }

  void _clearSearch() {
    _search.clear();
    _onSearchChanged('');
  }

  void _selectCategory(String? slug) {
    if (_search.text.isNotEmpty) _search.clear();
    context.read<ProductListBloc>().add(ProductsCategorySelected(slug));
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<ProductListBloc>()
      ..add(const ProductsFetched(isRefresh: true));
    await bloc.stream.firstWhere((s) => s.status != ProductListStatus.loading);
  }

  Future<void> _openSort() async {
    final bloc = context.read<ProductListBloc>();
    final sort = await showSortSheet(context, bloc.state.query.sort);
    if (sort != null) {
      bloc.add(ProductsSortChanged(sort));
      _scrollToTop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
            Spacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: Spacing.md,
                    ),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _clearSearch,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              BlocSelector<ProductListBloc, ProductListState, bool>(
                selector: (s) => s.query.sort.index != 0,
                builder: (context, isSorted) => IconButton.filledTonal(
                  tooltip: 'Sort products',
                  isSelected: isSorted,
                  onPressed: _openSort,
                  icon: Badge(
                    isLabelVisible: isSorted,
                    smallSize: 8,
                    child: const Icon(Icons.swap_vert_rounded),
                  ),
                  style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
                ),
              ),
            ],
          ),
        ),
        BlocSelector<ProductListBloc, ProductListState, String?>(
          selector: (s) => s.query.category,
          builder: (context, category) =>
              CategoryChips(selected: category, onSelected: _selectCategory),
        ),
        const SizedBox(height: Spacing.xs),
        Expanded(
          child: BlocConsumer<ProductListBloc, ProductListState>(
            // If a page doesn't fill the viewport there is nothing to scroll,
            // so check after layout whether more items are needed.
            listenWhen: (p, c) =>
                c.status == ProductListStatus.success &&
                p.products.length != c.products.length,
            listener: (_, _) =>
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _onScroll();
                }),
            builder: (context, state) {
              return switch (state.status) {
                ProductListStatus.initial ||
                ProductListStatus.loading => _SkeletonGrid(),
                ProductListStatus.failure => ErrorView(
                  failure: state.failure!,
                  onRetry: () => context.read<ProductListBloc>().add(
                    const ProductsFetched(),
                  ),
                ),
                ProductListStatus.empty => EmptyView(
                  icon: Icons.search_off_rounded,
                  title: 'No results',
                  message: state.query.isSearch
                      ? 'Nothing matches “${state.query.search}”. '
                            'Try a different term.'
                      : 'No products in this category yet.',
                  action: OutlinedButton(
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                      _selectCategory(null);
                    },
                    child: const Text('Show all products'),
                  ),
                ),
                ProductListStatus.success => RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: scheme.primary,
                  child: _ProductGrid(
                    state: state,
                    controller: _scroll,
                    selectedId: widget.selectedId,
                    onOpen: widget.onOpen,
                  ),
                ),
              };
            },
          ),
        ),
      ],
    );
  }
}

SliverGridDelegate _gridDelegate(BuildContext context, double width) {
  final columns = gridColumnsFor(width);
  const spacing = Spacing.md;
  final tileWidth =
      (width - Spacing.lg * 2 - spacing * (columns - 1)) / columns;
  final infoHeight = MediaQuery.textScalerOf(context)
      .scale(productCardInfoHeight);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: spacing,
    crossAxisSpacing: spacing,
    mainAxisExtent: tileWidth + infoHeight,
  );
}

class _SkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Spacing.lg),
        gridDelegate: _gridDelegate(context, constraints.maxWidth),
        itemCount: 8,
        itemBuilder: (_, _) => const ProductCardSkeleton(),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.state,
    required this.controller,
    required this.onOpen,
    this.selectedId,
  });

  final ProductListState state;
  final ScrollController controller;
  final ValueChanged<Product> onOpen;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              Spacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.isFromCache
                          ? 'Showing ${state.products.length} saved products'
                          : '${state.total} products',
                      style: text.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (state.query.sort.index != 0)
                    Text(
                      state.query.sort.label,
                      style: text.labelLarge?.copyWith(color: scheme.primary),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            sliver: SliverGrid.builder(
              gridDelegate: _gridDelegate(context, constraints.maxWidth),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                return ProductCard(
                  product: product,
                  isSelected: product.id == selectedId,
                  onTap: () => onOpen(product),
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: _Footer(state: state)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final ProductListState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget child;
    if (state.isLoadingMore) {
      child = const SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          semanticsLabel: 'Loading more products',
        ),
      );
    } else if (state.loadMoreFailure != null) {
      child = Column(
        children: [
          Text(
            state.loadMoreFailure!.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.error),
          ),
          const SizedBox(height: Spacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.read<ProductListBloc>().add(
              const ProductsNextPageRequested(),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      );
    } else if (state.hasReachedEnd) {
      child = Text(
        state.isFromCache
            ? 'Go online to load more'
            : 'You have seen all ${state.products.length} products',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: scheme.onSurfaceVariant),
      );
    } else {
      child = const SizedBox(height: 28);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.xl,
      ),
      child: Center(child: child),
    );
  }
}
