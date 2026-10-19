import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/network/api_endpoints.dart';
import 'package:shopsphere/features/products/data/datasources/product_remote_data_source.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';

import '../../../helpers/fixture_reader.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockApiClient client;
  late ProductRemoteDataSourceImpl dataSource;

  setUp(() {
    client = MockApiClient();
    dataSource = ProductRemoteDataSourceImpl(client);
    when(() => client.get(any(), query: any(named: 'query')))
        .thenAnswer((_) async => fixtureMap('products_page.json'));
  });

  Map<String, dynamic> capturedQuery() =>
      verify(() => client.get(any(), query: captureAny(named: 'query')))
              .captured
              .single
          as Map<String, dynamic>;

  test('lists products with limit/skip/select', () async {
    final page = await dataSource.getProducts(const ProductQuery(skip: 40));

    expect(page.products, hasLength(2));
    final query = capturedQuery();
    expect(query['limit'], 20);
    expect(query['skip'], 40);
    expect(query['select'], ApiEndpoints.productListFields);
    expect(query.containsKey('sortBy'), isFalse);
  });

  test('uses the search endpoint with q and sort params', () async {
    await dataSource.getProducts(
      const ProductQuery(search: ' phone ', sort: ProductSort.priceLowToHigh),
    );

    final captured = verify(
      () => client.get(captureAny(), query: captureAny(named: 'query')),
    ).captured;
    expect(captured[0], ApiEndpoints.productSearch);
    final query = captured[1] as Map<String, dynamic>;
    expect(query['q'], 'phone');
    expect(query['sortBy'], 'price');
    expect(query['order'], 'asc');
  });

  test('uses the category endpoint when a category is selected', () async {
    await dataSource.getProducts(const ProductQuery(category: 'smartphones'));

    verify(
      () => client.get(
        '/products/category/smartphones',
        query: any(named: 'query'),
      ),
    ).called(1);
  });

  test('maps every sort option to DummyJSON params', () {
    expect(ProductRemoteDataSourceImpl.sortParams(ProductSort.priceHighToLow), {
      'sortBy': 'price',
      'order': 'desc',
    });
    expect(ProductRemoteDataSourceImpl.sortParams(ProductSort.rating), {
      'sortBy': 'rating',
      'order': 'desc',
    });
    expect(ProductRemoteDataSourceImpl.sortParams(ProductSort.title), {
      'sortBy': 'title',
      'order': 'asc',
    });
  });

  test('throws ParseException on an unexpected payload', () async {
    when(() => client.get('/products/1')).thenAnswer((_) async => 'oops');

    expect(dataSource.getProduct(1), throwsA(isA<ParseException>()));
  });

  test('parses categories', () async {
    when(() => client.get(ApiEndpoints.categories))
        .thenAnswer((_) async => fixture('categories.json'));

    final categories = await dataSource.getCategories();

    expect(categories.map((c) => c.slug), contains('furniture'));
  });
}
