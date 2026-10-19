import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/error/failure_mapper.dart';
import 'package:shopsphere/core/storage/token_storage.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/cart/data/datasources/cart_data_sources.dart';
import 'package:shopsphere/features/cart/data/models/cart_item_model.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';
import 'package:shopsphere/features/cart/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl({
    required this._local,
    required this._remote,
    required this._tokens,
  });

  final CartLocalDataSource _local;
  final CartRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<Result<List<CartItem>>> loadCart() async => guard(() async {
    final List<CartItem> items = _local.readCart();
    return items;
  });

  @override
  Future<Result<void>> saveCart(List<CartItem> items) => guard(
    () => _local.writeCart(items.map(CartItemModel.fromEntity).toList()),
  );

  @override
  Future<Result<OrderConfirmation>> placeOrder(List<CartItem> items) =>
      guard(() async {
        final userId = await _tokens.readUserId();
        if (userId == null) throw const UnauthorizedException();
        return _remote.addCart(
          userId: userId,
          items: items.map(CartItemModel.fromEntity).toList(),
        );
      });
}
