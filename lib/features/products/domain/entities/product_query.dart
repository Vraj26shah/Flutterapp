import 'package:equatable/equatable.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';

enum ProductSort {
  relevance('Recommended'),
  priceLowToHigh('Price: low to high'),
  priceHighToLow('Price: high to low'),
  rating('Top rated'),
  title('Name: A–Z');

  const ProductSort(this.label);

  final String label;
}

/// What to fetch. Search and category are mutually exclusive because the
/// DummyJSON API cannot combine them in one request.
class ProductQuery extends Equatable {
  const ProductQuery({
    this.search = '',
    this.category,
    this.sort = ProductSort.relevance,
    this.skip = 0,
    this.limit = pageSize,
  });

  static const pageSize = 20;

  final String search;
  final String? category;
  final ProductSort sort;
  final int skip;
  final int limit;

  bool get isSearch => search.trim().isNotEmpty;

  /// The default "all products, page 1" query — the one we cache offline.
  bool get isDefaultFirstPage =>
      !isSearch &&
      category == null &&
      sort == ProductSort.relevance &&
      skip == 0;

  ProductQuery copyWith({
    String? search,
    String? Function()? category,
    ProductSort? sort,
    int? skip,
  }) => ProductQuery(
    search: search ?? this.search,
    category: category != null ? category() : this.category,
    sort: sort ?? this.sort,
    skip: skip ?? this.skip,
    limit: limit,
  );

  @override
  List<Object?> get props => [search, category, sort, skip, limit];
}

class ProductPage extends Equatable {
  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
    this.isFromCache = false,
  });

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  /// True when served from the offline cache instead of the network.
  final bool isFromCache;

  bool get hasMore => skip + products.length < total;

  @override
  List<Object?> get props => [products, total, skip, limit, isFromCache];
}

class Category extends Equatable {
  const Category({required this.slug, required this.name});

  final String slug;
  final String name;

  @override
  List<Object?> get props => [slug, name];
}
