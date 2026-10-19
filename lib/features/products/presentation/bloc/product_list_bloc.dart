import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';
import 'package:shopsphere/features/products/domain/usecases/product_usecases.dart';

// ---------------------------------------------------------------- events
sealed class ProductListEvent extends Equatable {
  const ProductListEvent();

  @override
  List<Object?> get props => [];
}

/// First load, or a full reload (retry / pull-to-refresh).
final class ProductsFetched extends ProductListEvent {
  const ProductsFetched({this.isRefresh = false});

  final bool isRefresh;

  @override
  List<Object?> get props => [isRefresh];
}

final class ProductsNextPageRequested extends ProductListEvent {
  const ProductsNextPageRequested();
}

final class ProductsCategorySelected extends ProductListEvent {
  const ProductsCategorySelected(this.slug);

  /// `null` means "All".
  final String? slug;

  @override
  List<Object?> get props => [slug];
}

/// Already debounced by the UI.
final class ProductsSearchChanged extends ProductListEvent {
  const ProductsSearchChanged(this.term);

  final String term;

  @override
  List<Object?> get props => [term];
}

final class ProductsSortChanged extends ProductListEvent {
  const ProductsSortChanged(this.sort);

  final ProductSort sort;

  @override
  List<Object?> get props => [sort];
}

// ----------------------------------------------------------------- state
enum ProductListStatus { initial, loading, success, empty, failure }

final class ProductListState extends Equatable {
  const ProductListState({
    this.status = ProductListStatus.initial,
    this.products = const [],
    this.query = const ProductQuery(),
    this.total = 0,
    this.hasReachedEnd = false,
    this.isLoadingMore = false,
    this.isFromCache = false,
    this.failure,
    this.loadMoreFailure,
  });

  final ProductListStatus status;
  final List<Product> products;
  final ProductQuery query;
  final int total;
  final bool hasReachedEnd;
  final bool isLoadingMore;

  /// The list is the offline cache, not live data.
  final bool isFromCache;

  /// Full-screen failure (first page).
  final Failure? failure;

  /// Inline failure when loading a further page; the list stays visible.
  final Failure? loadMoreFailure;

  ProductListState copyWith({
    ProductListStatus? status,
    List<Product>? products,
    ProductQuery? query,
    int? total,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    bool? isFromCache,
    Failure? Function()? failure,
    Failure? Function()? loadMoreFailure,
  }) => ProductListState(
    status: status ?? this.status,
    products: products ?? this.products,
    query: query ?? this.query,
    total: total ?? this.total,
    hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isFromCache: isFromCache ?? this.isFromCache,
    failure: failure != null ? failure() : this.failure,
    loadMoreFailure: loadMoreFailure != null
        ? loadMoreFailure()
        : this.loadMoreFailure,
  );

  @override
  List<Object?> get props => [
    status,
    products,
    query,
    total,
    hasReachedEnd,
    isLoadingMore,
    isFromCache,
    failure,
    loadMoreFailure,
  ];
}

// ------------------------------------------------------------------ bloc
/// Product catalogue: pagination, category filter, search and sort.
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  ProductListBloc({required this._getProducts, required this._searchProducts})
    : super(const ProductListState()) {
    on<ProductsFetched>(_onFetched);
    on<ProductsNextPageRequested>(_onNextPage);
    on<ProductsCategorySelected>(
      (e, emit) => _reload(
        emit,
        state.query.copyWith(search: '', category: () => e.slug, skip: 0),
      ),
    );
    on<ProductsSearchChanged>((e, emit) {
      final term = e.term.trim();
      if (term == state.query.search) return null;
      return _reload(
        emit,
        state.query.copyWith(search: term, category: () => null, skip: 0),
      );
    });
    on<ProductsSortChanged>((e, emit) {
      if (e.sort == state.query.sort) return null;
      return _reload(emit, state.query.copyWith(sort: e.sort, skip: 0));
    });
  }

  final GetProductsUseCase _getProducts;
  final SearchProductsUseCase _searchProducts;

  /// Incremented per first-page request; stale responses are dropped so a
  /// slow earlier search can never overwrite a newer one.
  int _generation = 0;

  Future<Result<ProductPage>> _load(ProductQuery q) =>
      q.isSearch ? _searchProducts(q) : _getProducts(q);

  Future<void> _onFetched(
    ProductsFetched event,
    Emitter<ProductListState> emit,
  ) => _reload(emit, state.query.copyWith(skip: 0), keepItems: event.isRefresh);

  Future<void> _reload(
    Emitter<ProductListState> emit,
    ProductQuery query, {
    bool keepItems = false,
  }) async {
    final generation = ++_generation;
    emit(
      state.copyWith(
        status: keepItems && state.products.isNotEmpty
            ? state.status
            : ProductListStatus.loading,
        products: keepItems ? null : const [],
        query: query,
        hasReachedEnd: false,
        isLoadingMore: false,
        failure: () => null,
        loadMoreFailure: () => null,
      ),
    );

    final result = await _load(query);
    if (generation != _generation) return; // a newer request superseded us

    switch (result) {
      case Ok(:final data):
        emit(
          state.copyWith(
            status: data.products.isEmpty
                ? ProductListStatus.empty
                : ProductListStatus.success,
            products: data.products,
            total: data.total,
            hasReachedEnd: !data.hasMore || data.isFromCache,
            isFromCache: data.isFromCache,
          ),
        );
      case Err(:final failure):
        emit(
          state.copyWith(
            status: ProductListStatus.failure,
            products: const [],
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onNextPage(
    ProductsNextPageRequested event,
    Emitter<ProductListState> emit,
  ) async {
    if (state.status != ProductListStatus.success ||
        state.hasReachedEnd ||
        state.isLoadingMore) {
      return;
    }
    final generation = _generation;
    final query = state.query.copyWith(skip: state.products.length);
    emit(state.copyWith(isLoadingMore: true, loadMoreFailure: () => null));

    final result = await _load(query);
    if (generation != _generation) return;

    switch (result) {
      case Ok(:final data):
        final products = [...state.products, ...data.products];
        emit(
          state.copyWith(
            products: products,
            total: data.total,
            isLoadingMore: false,
            hasReachedEnd:
                data.products.isEmpty || products.length >= data.total,
          ),
        );
      case Err(:final failure):
        emit(
          state.copyWith(isLoadingMore: false, loadMoreFailure: () => failure),
        );
    }
  }
}
