import 'package:shopsphere/features/cart/domain/entities/cart.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.productId,
    required super.title,
    required super.thumbnail,
    required super.price,
    required super.discountPercentage,
    required super.quantity,
    required super.stock,
  });

  factory CartItemModel.fromEntity(CartItem e) => CartItemModel(
    productId: e.productId,
    title: e.title,
    thumbnail: e.thumbnail,
    price: e.price,
    discountPercentage: e.discountPercentage,
    quantity: e.quantity,
    stock: e.stock,
  );

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    productId: (json['productId'] as num).toInt(),
    title: json['title'] as String,
    thumbnail: json['thumbnail'] as String? ?? '',
    price: (json['price'] as num).toDouble(),
    discountPercentage: (json['discountPercentage'] as num? ?? 0).toDouble(),
    quantity: (json['quantity'] as num).toInt(),
    stock: (json['stock'] as num? ?? 99).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'title': title,
    'thumbnail': thumbnail,
    'price': price,
    'discountPercentage': discountPercentage,
    'quantity': quantity,
    'stock': stock,
  };
}

/// Response of `POST /carts/add`.
class OrderConfirmationModel extends OrderConfirmation {
  const OrderConfirmationModel({
    required super.orderId,
    required super.total,
    required super.discountedTotal,
    required super.totalProducts,
    required super.totalQuantity,
  });

  factory OrderConfirmationModel.fromJson(Map<String, dynamic> json) =>
      OrderConfirmationModel(
        orderId: (json['id'] as num).toInt(),
        total: (json['total'] as num).toDouble(),
        discountedTotal: (json['discountedTotal'] as num).toDouble(),
        totalProducts: (json['totalProducts'] as num).toInt(),
        totalQuantity: (json['totalQuantity'] as num).toInt(),
      );
}
