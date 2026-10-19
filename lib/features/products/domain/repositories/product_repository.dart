import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';

abstract interface class ProductRepository {
  /// Paginated list, filtered by category or search text, sorted.
  Future<Result<ProductPage>> getProducts(ProductQuery query);

  Future<Result<Product>> getProduct(int id);

  Future<Result<List<Category>>> getCategories();
}
