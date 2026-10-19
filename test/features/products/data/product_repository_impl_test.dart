import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/products/data/models/product_model.dart';
import 'package:shopsphere/features/products/data/repositories/product_repository_impl.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';

import '../../../helpers/fixture_reader.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockProductRemoteDataSource remote;
  late MockProductLocalDataSource local;
  late ProductRepositoryImpl repository;

  final page = ProductPageModel.fromJson(fixtureMap('products_page.json'));
  final cached = ProductPageModel.fromJson(
    fixtureMap('products_page.json'),
    isFromCache: true,
  );
  const firstPage = ProductQuery();
  const secondPage = ProductQuery(skip: 20);

  setUpAll(() => registerFallbackValue(page));

  setUp(() {
    remote = MockProductRemoteDataSource();
    local = MockProductLocalDataSource();
    repository = ProductRepositoryImpl(remote: remote, local: local);
    when(() => local.cacheFirstPage(any())).thenAnswer((_) async {});
  });

  group('getProducts', () {
    test('returns the page and caches the default first page', () async {
      when(() => remote.getProducts(firstPage)).thenAnswer((_) async => page);

      final result = await repository.getProducts(firstPage);

      expect(result, isA<Ok<ProductPage>>());
      expect((result as Ok<ProductPage>).data.products, hasLength(2));
      verify(() => local.cacheFirstPage(page)).called(1);
    });

    test('does not cache later pages', () async {
      when(() => remote.getProducts(secondPage)).thenAnswer((_) async => page);

      await repository.getProducts(secondPage);

      verifyNever(() => local.cacheFirstPage(any()));
    });

    test('returns ServerFailure on a 5xx', () async {
      when(() => remote.getProducts(firstPage))
          .thenThrow(const ServerException(statusCode: 500));

      final result = await repository.getProducts(firstPage);

      expect((result as Err).failure, isA<ServerFailure>());
    });

    test('falls back to the offline cache when there is no network', () async {
      when(() => remote.getProducts(firstPage))
          .thenThrow(const NetworkException());
      when(() => local.getCachedFirstPage()).thenReturn(cached);

      final result = await repository.getProducts(firstPage);

      expect((result as Ok<ProductPage>).data.isFromCache, isTrue);
    });

    test('returns NetworkFailure offline when nothing is cached', () async {
      when(() => remote.getProducts(firstPage))
          .thenThrow(const NetworkException());
      when(() => local.getCachedFirstPage()).thenReturn(null);

      final result = await repository.getProducts(firstPage);

      expect((result as Err).failure, isA<NetworkFailure>());
    });

    test('a cache write error never breaks a successful request', () async {
      when(() => remote.getProducts(firstPage)).thenAnswer((_) async => page);
      when(() => local.cacheFirstPage(any())).thenThrow(const CacheException());

      final result = await repository.getProducts(firstPage);

      expect(result.isOk, isTrue);
    });
  });

  group('getProduct', () {
    test('maps a 404 to NotFoundFailure', () async {
      when(() => remote.getProduct(9999)).thenThrow(const NotFoundException());

      final result = await repository.getProduct(9999);

      expect((result as Err).failure, isA<NotFoundFailure>());
    });

    test('maps a timeout to TimeoutFailure', () async {
      when(() => remote.getProduct(1))
          .thenThrow(const RequestTimeoutException());

      final result = await repository.getProduct(1);

      expect((result as Err).failure, isA<TimeoutFailure>());
    });
  });
}
