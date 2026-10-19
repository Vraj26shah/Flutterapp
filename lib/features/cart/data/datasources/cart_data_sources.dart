import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/network/api_endpoints.dart';
import 'package:shopsphere/features/cart/data/models/cart_item_model.dart';

abstract interface class CartLocalDataSource {
  List<CartItemModel> readCart();
  Future<void> writeCart(List<CartItemModel> items);
}

/// Persists the cart as a JSON string in a Hive box (no codegen needed).
class CartLocalDataSourceImpl implements CartLocalDataSource {
  const CartLocalDataSourceImpl(this._box);

  static const boxName = 'cart';
  static const _key = 'items';

  final Box<String> _box;

  @override
  List<CartItemModel> readCart() {
    final raw = _box.get(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CartItemModel.fromJson)
          .toList();
    } catch (_) {
      throw const CacheException('Saved cart is corrupted');
    }
  }

  @override
  Future<void> writeCart(List<CartItemModel> items) async {
    try {
      await _box.put(_key, jsonEncode([for (final i in items) i.toJson()]));
    } catch (_) {
      throw const CacheException();
    }
  }
}

abstract interface class CartRemoteDataSource {
  Future<OrderConfirmationModel> addCart({
    required int userId,
    required List<CartItemModel> items,
  });
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  const CartRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<OrderConfirmationModel> addCart({
    required int userId,
    required List<CartItemModel> items,
  }) async {
    final data = await _client.post(
      ApiEndpoints.addCart,
      data: {
        'userId': userId,
        'products': [
          for (final i in items) {'id': i.productId, 'quantity': i.quantity},
        ],
      },
    );
    if (data is! Map<String, dynamic>) throw const ParseException();
    return OrderConfirmationModel.fromJson(data);
  }
}
