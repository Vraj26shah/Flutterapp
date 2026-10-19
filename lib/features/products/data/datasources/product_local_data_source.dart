import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/features/products/data/models/product_model.dart';

/// Offline cache for the first page of the catalogue and the categories.
abstract interface class ProductLocalDataSource {
  Future<void> cacheFirstPage(ProductPageModel page);
  ProductPageModel? getCachedFirstPage();
  Future<void> cacheCategories(List<CategoryModel> categories);
  List<CategoryModel>? getCachedCategories();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  const ProductLocalDataSourceImpl(this._box);

  static const boxName = 'products_cache';
  static const _firstPageKey = 'first_page';
  static const _categoriesKey = 'categories';

  final Box<String> _box;

  @override
  Future<void> cacheFirstPage(ProductPageModel page) =>
      _box.put(_firstPageKey, jsonEncode(page.toJson()));

  @override
  ProductPageModel? getCachedFirstPage() {
    final raw = _box.get(_firstPageKey);
    if (raw == null) return null;
    try {
      return ProductPageModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        isFromCache: true,
      );
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) => _box.put(
    _categoriesKey,
    jsonEncode([for (final c in categories) c.toJson()]),
  );

  @override
  List<CategoryModel>? getCachedCategories() {
    final raw = _box.get(_categoriesKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } catch (_) {
      throw const CacheException();
    }
  }
}
