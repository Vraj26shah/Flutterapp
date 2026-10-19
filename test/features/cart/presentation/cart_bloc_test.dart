import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';
import 'package:shopsphere/features/cart/presentation/bloc/cart_bloc.dart';

import '../../../helpers/mocks.dart';

const helmet = CartItem(
  productId: 144,
  title: 'Cricket Helmet',
  thumbnail: '',
  price: 40,
  discountPercentage: 10,
  quantity: 1,
  stock: 3,
);

const order = OrderConfirmation(
  orderId: 209,
  total: 80,
  discountedTotal: 72,
  totalProducts: 1,
  totalQuantity: 2,
);

void main() {
  late MockLoadCartUseCase loadCart;
  late MockSaveCartUseCase saveCart;
  late MockPlaceOrderUseCase placeOrder;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(<CartItem>[]);
  });

  setUp(() {
    loadCart = MockLoadCartUseCase();
    saveCart = MockSaveCartUseCase();
    placeOrder = MockPlaceOrderUseCase();
    when(() => saveCart(any())).thenAnswer((_) async => const Ok(null));
  });

  CartBloc build() =>
      CartBloc(loadCart: loadCart, saveCart: saveCart, placeOrder: placeOrder);

  blocTest<CartBloc, CartState>(
    'restores the persisted cart on start',
    setUp: () =>
        when(() => loadCart(any()))
            .thenAnswer((_) async => Ok([helmet.copyWith(quantity: 2)])),
    build: build,
    act: (bloc) => bloc.add(const CartStarted()),
    expect: () => [
      isA<CartState>()
          .having((s) => s.isLoaded, 'loaded', isTrue)
          .having((s) => s.totals.itemCount, 'count', 2)
          .having((s) => s.totals.total, 'total', 72),
    ],
  );

  blocTest<CartBloc, CartState>(
    'adding the same product merges quantities, capped at stock, and persists',
    build: build,
    act: (bloc) => bloc
      ..add(const CartItemAdded(helmet))
      ..add(CartItemAdded(helmet.copyWith(quantity: 5))),
    verify: (bloc) {
      expect(bloc.state.items.single.quantity, 3); // stock = 3
      verify(() => saveCart(any())).called(2);
    },
  );

  blocTest<CartBloc, CartState>(
    'changing quantity to 0 removes the item',
    build: build,
    seed: () => const CartState(items: [helmet], isLoaded: true),
    act: (bloc) => bloc.add(const CartQuantityChanged(144, 0)),
    expect: () => [
      isA<CartState>()
          .having((s) => s.items, 'items', isEmpty)
          .having((s) => s.totals, 'totals', const CartTotals.empty()),
    ],
  );

  blocTest<CartBloc, CartState>(
    'successful checkout emits [submitting, success] and clears the cart',
    setUp: () =>
        when(() => placeOrder(any())).thenAnswer((_) async => const Ok(order)),
    build: build,
    seed: () => CartState(
      items: [helmet.copyWith(quantity: 2)],
      totals: const CartTotals(
        subtotal: 80,
        discount: 8,
        total: 72,
        itemCount: 2,
      ),
      isLoaded: true,
    ),
    act: (bloc) => bloc.add(const CartCheckoutRequested()),
    expect: () => [
      isA<CartState>().having(
        (s) => s.checkoutStatus,
        'status',
        CheckoutStatus.submitting,
      ),
      isA<CartState>()
          .having((s) => s.checkoutStatus, 'status', CheckoutStatus.success)
          .having((s) => s.order, 'order', order)
          .having((s) => s.lastOrderTotal, 'paid', 72)
          .having((s) => s.items, 'items', isEmpty),
    ],
    verify: (_) => verify(() => saveCart(const [])).called(1),
  );

  blocTest<CartBloc, CartState>(
    'failed checkout keeps the cart and exposes the failure',
    setUp: () =>
        when(() => placeOrder(any()))
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: build,
    seed: () => const CartState(items: [helmet], isLoaded: true),
    act: (bloc) => bloc.add(const CartCheckoutRequested()),
    skip: 1,
    expect: () => [
      isA<CartState>()
          .having((s) => s.checkoutStatus, 'status', CheckoutStatus.failure)
          .having((s) => s.items, 'items', [helmet])
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );
}
