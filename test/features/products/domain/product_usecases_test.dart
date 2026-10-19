import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';
import 'package:shopsphere/features/products/domain/usecases/product_usecases.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockProductRepository repository;
  const page = ProductPage(products: [], total: 0, skip: 0, limit: 20);

  setUpAll(() => registerFallbackValue(const ProductQuery()));

  setUp(() {
    repository = MockProductRepository();
    when(
      () => repository.getProducts(any()),
    ).thenAnswer((_) async => const Ok(page));
  });

  test('GetProductsUseCase forwards the query unchanged', () async {
    const query = ProductQuery(category: 'beauty', sort: ProductSort.rating);

    await GetProductsUseCase(repository)(query);

    verify(() => repository.getProducts(query)).called(1);
  });

  test('SearchProductsUseCase trims the term and drops the category', () async {
    await SearchProductsUseCase(
      repository,
    )(const ProductQuery(search: '  phone ', category: 'beauty'));

    verify(
      () => repository.getProducts(const ProductQuery(search: 'phone')),
    ).called(1);
  });

  test('only the default first page is eligible for offline caching', () {
    expect(const ProductQuery().isDefaultFirstPage, isTrue);
    expect(const ProductQuery(skip: 20).isDefaultFirstPage, isFalse);
    expect(const ProductQuery(search: 'x').isDefaultFirstPage, isFalse);
  });
}
