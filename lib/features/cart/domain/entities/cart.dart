import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.productId,
    required this.title,
    required this.thumbnail,
    required this.price,
    required this.discountPercentage,
    required this.quantity,
    required this.stock,
  });

  final int productId;
  final String title;
  final String thumbnail;

  /// Unit price before discount.
  final double price;
  final double discountPercentage;
  final int quantity;

  /// Upper bound for [quantity].
  final int stock;

  double get lineSubtotal => price * quantity;
  double get lineDiscount => lineSubtotal * discountPercentage / 100;
  double get lineTotal => lineSubtotal - lineDiscount;

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    title: title,
    thumbnail: thumbnail,
    price: price,
    discountPercentage: discountPercentage,
    quantity: quantity ?? this.quantity,
    stock: stock,
  );

  @override
  List<Object?> get props => [
    productId,
    title,
    thumbnail,
    price,
    discountPercentage,
    quantity,
    stock,
  ];
}

/// Money summary of a cart. All values are rounded to cents.
class CartTotals extends Equatable {
  const CartTotals({
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.itemCount,
  });

  const CartTotals.empty()
    : this(subtotal: 0, discount: 0, total: 0, itemCount: 0);

  final double subtotal;
  final double discount;
  final double total;

  /// Sum of quantities (what the badge shows).
  final int itemCount;

  @override
  List<Object?> get props => [subtotal, discount, total, itemCount];
}

class OrderConfirmation extends Equatable {
  const OrderConfirmation({
    required this.orderId,
    required this.total,
    required this.discountedTotal,
    required this.totalProducts,
    required this.totalQuantity,
  });

  final int orderId;
  final double total;
  final double discountedTotal;
  final int totalProducts;
  final int totalQuantity;

  @override
  List<Object?> get props => [
    orderId,
    total,
    discountedTotal,
    totalProducts,
    totalQuantity,
  ];
}
