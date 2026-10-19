import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';
import 'package:shopsphere/features/cart/domain/repositories/cart_repository.dart';

/// Pure calculation of subtotal, discount and grand total.
class CalculateCartTotals {
  const CalculateCartTotals();

  CartTotals call(List<CartItem> items) {
    var subtotal = 0.0;
    var discount = 0.0;
    var count = 0;
    for (final item in items) {
      subtotal += item.lineSubtotal;
      discount += item.lineDiscount;
      count += item.quantity;
    }
    final s = _cents(subtotal);
    final d = _cents(discount);
    return CartTotals(
      subtotal: s,
      discount: d,
      total: _cents(s - d),
      itemCount: count,
    );
  }

  static double _cents(double v) => (v * 100).roundToDouble() / 100;
}

class LoadCartUseCase implements UseCase<List<CartItem>, NoParams> {
  const LoadCartUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<List<CartItem>>> call(NoParams params) =>
      _repository.loadCart();
}

class SaveCartUseCase implements UseCase<void, List<CartItem>> {
  const SaveCartUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<void>> call(List<CartItem> params) =>
      _repository.saveCart(params);
}

class PlaceOrderUseCase implements UseCase<OrderConfirmation, List<CartItem>> {
  const PlaceOrderUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<OrderConfirmation>> call(List<CartItem> params) async {
    if (params.isEmpty) {
      return const Err(UnknownFailure('Your cart is empty.'));
    }
    return _repository.placeOrder(params);
  }
}
