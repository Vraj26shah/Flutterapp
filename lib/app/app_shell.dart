import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/di/injection.dart';
import 'package:shopsphere/core/network/connectivity_cubit.dart';
import 'package:shopsphere/core/utils/breakpoints.dart';
import 'package:shopsphere/core/widgets/offline_banner.dart';
import 'package:shopsphere/features/auth/presentation/widgets/brand_logo.dart';
import 'package:shopsphere/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:shopsphere/features/cart/presentation/pages/cart_page.dart';
import 'package:shopsphere/features/products/presentation/bloc/categories_cubit.dart';
import 'package:shopsphere/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:shopsphere/features/products/presentation/pages/products_page.dart';
import 'package:shopsphere/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:shopsphere/features/profile/presentation/pages/profile_page.dart';

/// Signed-in shell: bottom navigation on phones, a navigation rail on
/// tablets / landscape. Tabs keep their state in an [IndexedStack].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = ['Discover', 'Your cart', 'Profile'];

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ProductListBloc>()..add(const ProductsFetched()),
        ),
        BlocProvider(create: (_) => sl<CategoriesCubit>()..load()),
        BlocProvider(create: (_) => sl<ProfileCubit>()..load()),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = WindowSize.of(constraints.maxWidth);
          final pages = IndexedStack(
            index: _index,
            children: [
              const ProductsPage(),
              CartPage(onBrowse: () => _select(0)),
              const ProfilePage(),
            ],
          );
          final isOffline = context.watch<ConnectivityCubit>().state;

          return Scaffold(
            appBar: AppBar(
              titleSpacing: size.isCompact ? null : 24,
              title: Row(
                children: [
                  if (size.isCompact) ...[
                    const BrandLogo(size: 32),
                    const SizedBox(width: 12),
                  ],
                  Flexible(child: Text(_titles[_index])),
                ],
              ),
              actions: [
                if (_index != 1) _CartAction(onPressed: () => _select(1)),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: Size.zero,
                child: OfflineBanner(isOffline: isOffline),
              ),
            ),
            body: size.isCompact
                ? pages
                : Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _index,
                        onDestinationSelected: _select,
                        labelType: NavigationRailLabelType.all,
                        leading: const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: BrandLogo(size: 40),
                        ),
                        destinations: [
                          for (final d in _destinations())
                            NavigationRailDestination(
                              icon: d.icon,
                              selectedIcon: d.selectedIcon,
                              label: Text(d.label),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: pages),
                    ],
                  ),
            bottomNavigationBar: size.isCompact
                ? NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    destinations: [
                      for (final d in _destinations())
                        NavigationDestination(
                          icon: d.icon,
                          selectedIcon: d.selectedIcon,
                          label: d.label,
                        ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  List<_Destination> _destinations() => [
    const _Destination(
      Icon(Icons.storefront_outlined),
      Icon(Icons.storefront_rounded),
      'Shop',
    ),
    const _Destination(
      _CartIcon(selected: false),
      _CartIcon(selected: true),
      'Cart',
    ),
    const _Destination(
      Icon(Icons.person_outline_rounded),
      Icon(Icons.person_rounded),
      'Profile',
    ),
  ];
}

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);

  final Widget icon;
  final Widget selectedIcon;
  final String label;
}

/// Cart icon with a live item-count badge.
class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartBloc, int>(
      (b) => b.state.totals.itemCount,
    );
    return Badge.count(
      count: count,
      isLabelVisible: count > 0,
      child: Icon(
        selected ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined,
        semanticLabel: count > 0 ? 'Cart, $count items' : 'Cart',
      ),
    );
  }
}

class _CartAction extends StatelessWidget {
  const _CartAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Open cart',
    onPressed: onPressed,
    icon: const _CartIcon(selected: false),
  );
}
