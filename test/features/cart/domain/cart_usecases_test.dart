import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';
import 'package:shopsphere/features/cart/domain/usecases/cart_usecases.dart';

import '../../../helpers/mocks.dart';

CartItem item({
  int id = 1,
  double price = 10,
  double discount = 0,
  int qty = 1,
}) => CartItem(
  productId: id,
  title: 'P$id',
  thumbnail: '',
  price: price,
  discountPercentage: discount,
  quantity: qty,
  stock: 50,
);

void main() {
  group('CalculateCartTotals', () {
    const calculate = CalculateCartTotals();

    test('empty cart totals are zero', () {
      expect(calculate(const []), const CartTotals.empty());
    });

    test('sums subtotal, discount, total and item count', () {
      final totals = calculate([
        item(price: 10, discount: 10, qty: 2), // 20.00 − 2.00
        item(id: 2, price: 5.5, qty: 3), //       16.50 − 0
      ]);

      expect(totals.subtotal, 36.5);
      expect(totals.discount, 2.0);
      expect(totals.total, 34.5);
      expect(totals.itemCount, 5);
    });

    test('rounds to cents', () {
      // 12.99 × 12.2% = 1.58478 → 1.58
      final totals = calculate([item(price: 12.99, discount: 12.2)]);

      expect(totals.discount, 1.58);
      expect(totals.total, 11.41);
    });
  });

  group('PlaceOrderUseCase', () {
    late MockCartRepository repository;
    late PlaceOrderUseCase placeOrder;

    setUp(() {
      repository = MockCartRepository();
      placeOrder = PlaceOrderUseCase(repository);
    });

    test('rejects an empty cart without calling the API', () async {
      final result = await placeOrder(const []);

      expect((result as Err).failure, isA<UnknownFailure>());
      verifyZeroInteractions(repository);
    });

    test('delegates a non-empty cart to the repository', () async {
      const order = OrderConfirmation(
        orderId: 7,
        total: 10,
        discountedTotal: 10,
        totalProducts: 1,
        totalQuantity: 1,
      );
      final items = [item()];
      when(() => repository.placeOrder(items))
          .thenAnswer((_) async => const Ok(order));

      expect(await placeOrder(items), isA<Ok<OrderConfirmation>>());
    });
  });
}
