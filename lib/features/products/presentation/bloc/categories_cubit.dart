import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';
import 'package:shopsphere/features/products/domain/usecases/product_usecases.dart';

enum CategoriesStatus { loading, success, failure }

final class CategoriesState extends Equatable {
  const CategoriesState({
    this.status = CategoriesStatus.loading,
    this.categories = const [],
  });

  final CategoriesStatus status;
  final List<Category> categories;

  @override
  List<Object?> get props => [status, categories];
}

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._getCategories) : super(const CategoriesState());

  final GetCategoriesUseCase _getCategories;

  Future<void> load() async {
    emit(const CategoriesState());
    final result = await _getCategories(const NoParams());
    emit(switch (result) {
      Ok(:final data) => CategoriesState(
        status: CategoriesStatus.success,
        categories: data,
      ),
      Err() => const CategoriesState(status: CategoriesStatus.failure),
    });
  }
}
