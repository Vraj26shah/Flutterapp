import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/network/api_endpoints.dart';
import 'package:shopsphere/features/products/data/models/product_model.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';

abstract interface class ProductRemoteDataSource {
  Future<ProductPageModel> getProducts(ProductQuery query);
  Future<ProductModel> getProduct(int id);
  Future<List<CategoryModel>> getCategories();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  const ProductRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<ProductPageModel> getProducts(ProductQuery query) async {
    final path = query.isSearch
        ? ApiEndpoints.productSearch
        : query.category != null
        ? ApiEndpoints.productsByCategory(query.category!)
        : ApiEndpoints.products;

    final params = <String, dynamic>{
      'limit': query.limit,
      'skip': query.skip,
      'select': ApiEndpoints.productListFields,
      if (query.isSearch) 'q': query.search.trim(),
      ...sortParams(query.sort),
    };

    final data = await _client.get(path, query: params);
    if (data is! Map<String, dynamic>) throw const ParseException();
    return ProductPageModel.fromJson(data);
  }

  @override
  Future<ProductModel> getProduct(int id) async {
    final data = await _client.get(ApiEndpoints.product(id));
    if (data is! Map<String, dynamic>) throw const ParseException();
    return ProductModel.fromJson(data);
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final data = await _client.get(ApiEndpoints.categories);
    if (data is! List<dynamic>) throw const ParseException();
    return data
        .cast<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList(growable: false);
  }

  /// Maps the domain sort option to DummyJSON's `sortBy` / `order` params.
  static Map<String, String> sortParams(ProductSort sort) => switch (sort) {
    ProductSort.relevance => const {},
    ProductSort.priceLowToHigh => const {'sortBy': 'price', 'order': 'asc'},
    ProductSort.priceHighToLow => const {'sortBy': 'price', 'order': 'desc'},
    ProductSort.rating => const {'sortBy': 'rating', 'order': 'desc'},
    ProductSort.title => const {'sortBy': 'title', 'order': 'asc'},
  };
}
