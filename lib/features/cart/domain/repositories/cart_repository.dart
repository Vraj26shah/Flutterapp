import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';

abstract interface class CartRepository {
  /// Loads the locally persisted cart.
  Future<Result<List<CartItem>>> loadCart();

  /// Persists the whole cart locally.
  Future<Result<void>> saveCart(List<CartItem> items);

  /// Places the order via `POST /carts/add` (simulated by DummyJSON).
  Future<Result<OrderConfirmation>> placeOrder(List<CartItem> items);
}
