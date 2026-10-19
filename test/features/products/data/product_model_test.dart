import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/features/products/data/models/product_model.dart';

import '../../../helpers/fixture_reader.dart';

void main() {
  group('ProductModel.fromJson', () {
    test('parses a full product with images and reviews', () {
      final product = ProductModel.fromJson(
        fixtureMap('product_details.json'),
      );

      expect(product.id, 1);
      expect(product.title, 'Essence Mascara Lash Princess');
      expect(product.brand, 'Essence');
      expect(product.price, 9.99);
      expect(product.discountPercentage, 10.48);
      expect(product.stock, 99);
      expect(product.isInStock, isTrue);
      expect(product.images, isNotEmpty);
      expect(product.reviews, hasLength(3));
      expect(product.reviews.first.reviewerName, 'Eleanor Collins');
      expect(product.reviews.first.date, isNotNull);
    });

    test('computes the discounted price rounded to cents', () {
      final product = ProductModel.fromJson(
        fixtureMap('product_details.json'),
      );
      // 9.99 * (1 - 0.1048) = 8.943...
      expect(product.finalPrice, 8.94);
    });

    test('handles a missing brand and missing detail fields', () {
      final page = ProductPageModel.fromJson(
        fixtureMap('products_page_no_brand.json'),
      );
      final product = page.products.single;

      expect(product.brand, isNull);
      expect(product.reviews, isEmpty);
      expect(product.gallery, [product.thumbnail]);
      expect(product.isLowStock, isTrue);
    });

    test('round-trips through toJson for the offline cache', () {
      final original = ProductModel.fromJson(fixtureMap('product_details.json'));
      final copy = ProductModel.fromJson(original.toJson());
      expect(copy, original);
    });
  });

  group('ProductPageModel.fromJson', () {
    test('parses pagination metadata', () {
      final page = ProductPageModel.fromJson(fixtureMap('products_page.json'));

      expect(page.products, hasLength(2));
      expect(page.total, 194);
      expect(page.skip, 0);
      expect(page.hasMore, isTrue);
      expect(page.isFromCache, isFalse);
    });
  });

  test('CategoryModel parses the categories endpoint', () {
    final list = (fixture('categories.json') as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
    expect(list.first.slug, 'beauty');
    expect(list.first.name, 'Beauty');
  });
}
