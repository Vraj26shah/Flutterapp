import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shopsphere/features/cart/data/datasources/cart_data_sources.dart';
import 'package:shopsphere/features/cart/data/models/cart_item_model.dart';
import 'package:shopsphere/features/products/data/datasources/product_local_data_source.dart';
import 'package:shopsphere/features/products/data/models/product_model.dart';

import '../../../helpers/fixture_reader.dart';

void main() {
  late Directory dir;
  late Box<String> box;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(dir.path);
    box = await Hive.openBox<String>('test_box');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  group('ProductLocalDataSource', () {
    test('caches and restores the first page, flagged as cached', () async {
      final source = ProductLocalDataSourceImpl(box);
      final page = ProductPageModel.fromJson(fixtureMap('products_page.json'));

      expect(source.getCachedFirstPage(), isNull);
      await source.cacheFirstPage(page);
      final restored = source.getCachedFirstPage()!;

      expect(restored.products, page.products);
      expect(restored.isFromCache, isTrue);
    });

    test('caches categories', () async {
      final source = ProductLocalDataSourceImpl(box);
      await source.cacheCategories(const [
        CategoryModel(slug: 'beauty', name: 'Beauty'),
      ]);

      expect(source.getCachedCategories()!.single.slug, 'beauty');
    });
  });

  group('CartLocalDataSource', () {
    test('persists the cart across instances (app restart)', () async {
      const item = CartItemModel(
        productId: 1,
        title: 'Mascara',
        thumbnail: '',
        price: 9.99,
        discountPercentage: 10,
        quantity: 3,
        stock: 99,
      );
      await CartLocalDataSourceImpl(box).writeCart([item]);

      final restored = CartLocalDataSourceImpl(box).readCart();

      expect(restored, [item]);
    });

    test('an empty box yields an empty cart', () {
      expect(CartLocalDataSourceImpl(box).readCart(), isEmpty);
    });
  });
}
