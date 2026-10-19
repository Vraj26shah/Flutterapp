import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';
import 'package:shopsphere/features/products/presentation/bloc/product_list_bloc.dart';

import '../../../helpers/mocks.dart';

List<Product> products(int from, int count) => [
  for (var i = from; i < from + count; i++)
    Product(id: i, title: 'P$i', price: 1, thumbnail: ''),
];

ProductPage pageOf(int skip, int count, int total) => ProductPage(
  products: products(skip, count),
  total: total,
  skip: skip,
  limit: 20,
);

void main() {
  late MockGetProductsUseCase getProducts;
  late MockSearchProductsUseCase searchProducts;

  setUpAll(() => registerFallbackValue(const ProductQuery()));

  setUp(() {
    getProducts = MockGetProductsUseCase();
    searchProducts = MockSearchProductsUseCase();
  });

  ProductListBloc build() => ProductListBloc(
    getProducts: getProducts,
    searchProducts: searchProducts,
  );

  blocTest<ProductListBloc, ProductListState>(
    'emits [loading, success] on first fetch',
    setUp: () => when(
      () => getProducts(any()),
    ).thenAnswer((_) async => Ok(pageOf(0, 20, 194))),
    build: build,
    act: (bloc) => bloc.add(const ProductsFetched()),
    expect: () => [
      isA<ProductListState>().having(
        (s) => s.status,
        'status',
        ProductListStatus.loading,
      ),
      isA<ProductListState>()
          .having((s) => s.status, 'status', ProductListStatus.success)
          .having((s) => s.products.length, 'count', 20)
          .having((s) => s.hasReachedEnd, 'end', isFalse),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'emits [loading, failure] when the first page fails',
    setUp: () => when(
      () => getProducts(any()),
    ).thenAnswer((_) async => const Err(ServerFailure())),
    build: build,
    act: (bloc) => bloc.add(const ProductsFetched()),
    expect: () => [
      isA<ProductListState>().having(
        (s) => s.status,
        'status',
        ProductListStatus.loading,
      ),
      isA<ProductListState>()
          .having((s) => s.status, 'status', ProductListStatus.failure)
          .having((s) => s.failure, 'failure', const ServerFailure()),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'loads the next page with skip = current length and appends it',
    setUp: () {
      when(
        () => getProducts(const ProductQuery()),
      ).thenAnswer((_) async => Ok(pageOf(0, 20, 30)));
      when(
        () => getProducts(const ProductQuery(skip: 20)),
      ).thenAnswer((_) async => Ok(pageOf(20, 10, 30)));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const ProductsFetched());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ProductsNextPageRequested());
    },
    skip: 2,
    expect: () => [
      isA<ProductListState>().having((s) => s.isLoadingMore, 'more', isTrue),
      isA<ProductListState>()
          .having((s) => s.products.length, 'count', 30)
          .having((s) => s.hasReachedEnd, 'end', isTrue)
          .having((s) => s.isLoadingMore, 'more', isFalse),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'a failed next page keeps the list and exposes loadMoreFailure',
    setUp: () {
      when(
        () => getProducts(const ProductQuery()),
      ).thenAnswer((_) async => Ok(pageOf(0, 20, 30)));
      when(
        () => getProducts(const ProductQuery(skip: 20)),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const ProductsFetched());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ProductsNextPageRequested());
    },
    skip: 3,
    expect: () => [
      isA<ProductListState>()
          .having((s) => s.products.length, 'count', 20)
          .having((s) => s.loadMoreFailure, 'failure', isA<NetworkFailure>()),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'search uses SearchProductsUseCase and emits empty for no results',
    setUp: () => when(() => searchProducts(any())).thenAnswer(
      (_) async =>
          const Ok(ProductPage(products: [], total: 0, skip: 0, limit: 20)),
    ),
    build: build,
    act: (bloc) => bloc.add(const ProductsSearchChanged('zzzqqq')),
    expect: () => [
      isA<ProductListState>().having(
        (s) => s.query.search,
        'search',
        'zzzqqq',
      ),
      isA<ProductListState>().having(
        (s) => s.status,
        'status',
        ProductListStatus.empty,
      ),
    ],
    verify: (_) => verifyNever(() => getProducts(any())),
  );

  blocTest<ProductListBloc, ProductListState>(
    'selecting a category clears the search and resets pagination',
    setUp: () => when(
      () => getProducts(any()),
    ).thenAnswer((_) async => Ok(pageOf(0, 5, 5))),
    build: build,
    seed: () => const ProductListState(
      status: ProductListStatus.success,
      query: ProductQuery(search: 'phone', skip: 40),
    ),
    act: (bloc) => bloc.add(const ProductsCategorySelected('smartphones')),
    verify: (_) => verify(
      () => getProducts(const ProductQuery(category: 'smartphones')),
    ).called(1),
  );

  blocTest<ProductListBloc, ProductListState>(
    'drops a stale response when a newer search was issued',
    setUp: () {
      when(
        () => searchProducts(const ProductQuery(search: 'ph')),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Ok(pageOf(0, 3, 3));
      });
      when(
        () => searchProducts(const ProductQuery(search: 'phone')),
      ).thenAnswer((_) async => Ok(pageOf(100, 1, 1)));
    },
    build: build,
    act: (bloc) async {
      bloc
        ..add(const ProductsSearchChanged('ph'))
        ..add(const ProductsSearchChanged('phone'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    },
    verify: (bloc) {
      expect(bloc.state.query.search, 'phone');
      expect(bloc.state.products.single.id, 100);
    },
  );
}
