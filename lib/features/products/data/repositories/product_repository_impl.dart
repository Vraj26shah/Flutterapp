import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/error/failure_mapper.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/products/data/datasources/product_local_data_source.dart';
import 'package:shopsphere/features/products/data/datasources/product_remote_data_source.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';
import 'package:shopsphere/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl({required this._remote, required this._local});

  final ProductRemoteDataSource _remote;
  final ProductLocalDataSource _local;

  @override
  Future<Result<ProductPage>> getProducts(ProductQuery query) async {
    try {
      final page = await _remote.getProducts(query);
      if (query.isDefaultFirstPage) {
        await _tryCache(() => _local.cacheFirstPage(page));
      }
      return Ok(page);
    } on NetworkException catch (e) {
      // Offline: fall back to the cached catalogue when we have one.
      if (query.isDefaultFirstPage) {
        final cached = _tryRead(_local.getCachedFirstPage);
        if (cached != null) return Ok(cached);
      }
      return Err(mapExceptionToFailure(e));
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Product>> getProduct(int id) =>
      guard(() => _remote.getProduct(id));

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final categories = await _remote.getCategories();
      await _tryCache(() => _local.cacheCategories(categories));
      return Ok(categories);
    } on NetworkException catch (e) {
      final cached = _tryRead(_local.getCachedCategories);
      if (cached != null) return Ok(cached);
      return Err(mapExceptionToFailure(e));
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }

  /// Cache writes are best-effort: a failure must never break the request.
  Future<void> _tryCache(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      // Ignored on purpose: caching is an optimisation, not a requirement.
    }
  }

  T? _tryRead<T>(T? Function() read) {
    try {
      return read();
    } catch (_) {
      return null;
    }
  }
}
