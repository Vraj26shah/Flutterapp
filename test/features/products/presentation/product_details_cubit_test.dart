import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/presentation/bloc/product_details_cubit.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockGetProductDetailsUseCase getDetails;
  const product = Product(id: 1, title: 'Mascara', price: 9.99, thumbnail: '');

  setUp(() => getDetails = MockGetProductDetailsUseCase());

  blocTest<ProductDetailsCubit, ProductDetailsState>(
    'emits [loading, loaded] for an existing product',
    setUp: () =>
        when(() => getDetails(1)).thenAnswer((_) async => const Ok(product)),
    build: () => ProductDetailsCubit(getDetails),
    act: (cubit) => cubit.load(1),
    expect: () => const [
      ProductDetailsLoading(),
      ProductDetailsLoaded(product),
    ],
  );

  blocTest<ProductDetailsCubit, ProductDetailsState>(
    'emits [loading, failure(NotFound)] for /products/9999',
    setUp: () => when(
      () => getDetails(9999),
    ).thenAnswer((_) async => const Err(NotFoundFailure())),
    build: () => ProductDetailsCubit(getDetails),
    act: (cubit) => cubit.load(9999),
    expect: () => const [
      ProductDetailsLoading(),
      ProductDetailsFailure(NotFoundFailure()),
    ],
  );
}
