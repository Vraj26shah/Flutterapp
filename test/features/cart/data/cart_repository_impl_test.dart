import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/cart/data/models/cart_item_model.dart';
import 'package:shopsphere/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';

import '../../../helpers/fixture_reader.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockCartLocalDataSource local;
  late MockCartRemoteDataSource remote;
  late MockTokenStorage tokens;
  late CartRepositoryImpl repository;

  const item = CartItemModel(
    productId: 144,
    title: 'Cricket Helmet',
    thumbnail: '',
    price: 44.99,
    discountPercentage: 9.64,
    quantity: 2,
    stock: 10,
  );

  setUpAll(() => registerFallbackValue(<CartItemModel>[]));

  setUp(() {
    local = MockCartLocalDataSource();
    remote = MockCartRemoteDataSource();
    tokens = MockTokenStorage();
    repository = CartRepositoryImpl(
      local: local,
      remote: remote,
      tokens: tokens,
    );
  });

  test('loadCart returns persisted items', () async {
    when(() => local.readCart()).thenReturn([item]);

    final result = await repository.loadCart();

    expect((result as Ok<List<CartItem>>).data, [item]);
  });

  test('a corrupted cart becomes CacheFailure', () async {
    when(() => local.readCart()).thenThrow(const CacheException());

    expect((await repository.loadCart() as Err).failure, isA<CacheFailure>());
  });

  test('placeOrder posts the items for the signed-in user', () async {
    when(() => tokens.readUserId()).thenAnswer((_) async => 1);
    when(
      () => remote.addCart(userId: 1, items: any(named: 'items')),
    ).thenAnswer(
      (_) async => OrderConfirmationModel.fromJson(fixtureMap('cart_add.json')),
    );

    final result = await repository.placeOrder([item]);

    expect((result as Ok<OrderConfirmation>).data.totalQuantity, 2);
  });

  test('placeOrder without a session is an UnauthorizedFailure', () async {
    when(() => tokens.readUserId()).thenAnswer((_) async => null);

    final result = await repository.placeOrder([item]);

    expect((result as Err).failure, isA<UnauthorizedFailure>());
    verifyNever(
      () => remote.addCart(
        userId: any(named: 'userId'),
        items: any(named: 'items'),
      ),
    );
  });

  test('placeOrder maps a server error', () async {
    when(() => tokens.readUserId()).thenAnswer((_) async => 1);
    when(
      () => remote.addCart(
        userId: any(named: 'userId'),
        items: any(named: 'items'),
      ),
    ).thenThrow(const ServerException(statusCode: 500));

    expect(
      (await repository.placeOrder([item]) as Err).failure,
      isA<ServerFailure>(),
    );
  });
}
