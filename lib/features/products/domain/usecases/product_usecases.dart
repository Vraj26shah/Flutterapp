import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';
import 'package:shopsphere/features/products/domain/repositories/product_repository.dart';

class GetProductsUseCase implements UseCase<ProductPage, ProductQuery> {
  const GetProductsUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<Result<ProductPage>> call(ProductQuery params) =>
      _repository.getProducts(params);
}

/// Full-text search. Normalises the term and delegates to the repository.
class SearchProductsUseCase implements UseCase<ProductPage, ProductQuery> {
  const SearchProductsUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<Result<ProductPage>> call(ProductQuery params) =>
      _repository.getProducts(
        params.copyWith(search: params.search.trim(), category: () => null),
      );
}

class GetProductDetailsUseCase implements UseCase<Product, int> {
  const GetProductDetailsUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<Result<Product>> call(int params) => _repository.getProduct(params);
}

class GetCategoriesUseCase implements UseCase<List<Category>, NoParams> {
  const GetCategoriesUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<Result<List<Category>>> call(NoParams params) =>
      _repository.getCategories();
}
