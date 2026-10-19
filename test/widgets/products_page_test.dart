import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/network/connectivity_cubit.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';
import 'package:shopsphere/features/products/presentation/bloc/categories_cubit.dart';
import 'package:shopsphere/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:shopsphere/features/products/presentation/pages/products_page.dart';
import 'package:shopsphere/features/products/presentation/widgets/product_card.dart';

import '../helpers/mocks.dart';
import '../helpers/pump.dart';

final _products = [
  for (var i = 1; i <= 8; i++)
    Product(
      id: i,
      // Long titles and five-figure prices are the overflow worst case.
      title: i.isEven ? 'Product $i' : 'A very long product name number $i',
      brand: i == 3 ? null : 'Brand',
      category: 'home-decoration',
      price: i == 1 ? 36999.99 : 9.99 * i,
      discountPercentage: i.isOdd ? 12.5 : 0,
      rating: 4.2,
      stock: i == 2 ? 0 : 10,
      thumbnail: '',
    ),
];

void main() {
  late MockProductListBloc listBloc;
  late MockCategoriesCubit categories;
  late MockConnectivityCubit connectivity;

  setUpAll(() => registerFallbackValue(const ProductsFetched()));

  setUp(() {
    listBloc = MockProductListBloc();
    categories = MockCategoriesCubit();
    connectivity = MockConnectivityCubit();
    when(() => categories.state).thenReturn(
      const CategoriesState(
        status: CategoriesStatus.success,
        categories: [
          Category(slug: 'beauty', name: 'Beauty'),
          Category(slug: 'home-decoration', name: 'Home Decoration'),
        ],
      ),
    );
    when(() => connectivity.state).thenReturn(false);
  });

  Widget page() => MultiBlocProvider(
    providers: [
      BlocProvider<ProductListBloc>.value(value: listBloc),
      BlocProvider<CategoriesCubit>.value(value: categories),
      BlocProvider<ConnectivityCubit>.value(value: connectivity),
    ],
    child: const ProductsPage(),
  );

  void seed(ProductListState state) =>
      when(() => listBloc.state).thenReturn(state);

  final success = ProductListState(
    status: ProductListStatus.success,
    products: _products,
    total: 194,
  );

  for (final entry in allSizes.entries) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('catalogue has no overflow: ${entry.key} @ ${scale}x', (
        tester,
      ) async {
        seed(success);
        await pumpAt(tester, page(), size: entry.value, textScale: scale);

        expect(tester.takeException(), isNull);
        expect(find.byType(ProductCard), findsWidgets);
      });
    }
  }

  testWidgets('tablet landscape shows the master–detail placeholder', (
    tester,
  ) async {
    seed(success);
    await pumpAt(tester, page(), size: tabletLandscape);

    expect(find.text('Select a product'), findsOneWidget);
  });

  testWidgets('compact grid uses 2 columns, tablet uses more', (tester) async {
    seed(success);
    await pumpAt(tester, page(), size: phonePortrait);
    final phoneFirstRow = tester.getTopLeft(find.byType(ProductCard).at(1)).dy;
    final phoneThird = tester.getTopLeft(find.byType(ProductCard).at(2)).dy;
    expect(phoneThird, greaterThan(phoneFirstRow)); // 3rd card wraps

    await pumpAt(tester, page(), size: tabletPortrait);
    final tabletFirst = tester.getTopLeft(find.byType(ProductCard).at(0)).dy;
    final tabletThird = tester.getTopLeft(find.byType(ProductCard).at(2)).dy;
    expect(tabletThird, tabletFirst); // 3 columns on one row
  });

  testWidgets('failure shows ErrorView and Retry refetches', (tester) async {
    seed(
      const ProductListState(
        status: ProductListStatus.failure,
        failure: ServerFailure(),
      ),
    );
    await pumpAt(tester, page());

    await tester.tap(find.text('Retry'));
    verify(() => listBloc.add(const ProductsFetched())).called(1);
  });

  testWidgets('empty search shows the no-results state', (tester) async {
    seed(
      const ProductListState(
        status: ProductListStatus.empty,
        query: ProductQuery(search: 'zzz'),
      ),
    );
    await pumpAt(tester, page());

    expect(find.text('No results'), findsOneWidget);
    await tester.tap(find.text('Show all products'));
    verify(() => listBloc.add(const ProductsCategorySelected(null))).called(1);
  });

  testWidgets('selecting a category chip dispatches the filter', (
    tester,
  ) async {
    seed(success);
    await pumpAt(tester, page());

    await tester.tap(find.text('Beauty'));
    verify(() => listBloc.add(const ProductsCategorySelected('beauty')))
        .called(1);
  });

  testWidgets('end of list shows the footer message', (tester) async {
    seed(
      ProductListState(
        status: ProductListStatus.success,
        products: _products.take(2).toList(),
        total: 2,
        hasReachedEnd: true,
      ),
    );
    await pumpAt(tester, page());

    expect(find.text('You have seen all 2 products'), findsOneWidget);
  });
}
