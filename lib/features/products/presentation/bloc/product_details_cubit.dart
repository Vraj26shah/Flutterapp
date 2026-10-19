import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/domain/usecases/product_usecases.dart';

sealed class ProductDetailsState extends Equatable {
  const ProductDetailsState();

  @override
  List<Object?> get props => [];
}

final class ProductDetailsLoading extends ProductDetailsState {
  const ProductDetailsLoading();
}

final class ProductDetailsLoaded extends ProductDetailsState {
  const ProductDetailsLoaded(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

final class ProductDetailsFailure extends ProductDetailsState {
  const ProductDetailsFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit(this._getDetails) : super(const ProductDetailsLoading());

  final GetProductDetailsUseCase _getDetails;
  int? _productId;

  Future<void> load(int id) async {
    _productId = id;
    emit(const ProductDetailsLoading());
    final result = await _getDetails(id);
    if (isClosed || id != _productId) return;
    emit(switch (result) {
      Ok(:final data) => ProductDetailsLoaded(data),
      Err(:final failure) => ProductDetailsFailure(failure),
    });
  }

  Future<void> retry() async {
    final id = _productId;
    if (id != null) await load(id);
  }
}
