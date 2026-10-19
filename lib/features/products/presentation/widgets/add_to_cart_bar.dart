import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';
import 'package:shopsphere/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:shopsphere/features/cart/presentation/widgets/quantity_stepper.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';

extension ProductToCartItem on Product {
  CartItem toCartItem(int quantity) => CartItem(
    productId: id,
    title: title,
    thumbnail: thumbnail,
    price: price,
    discountPercentage: discountPercentage,
    quantity: quantity,
    stock: stock,
  );
}

/// Quantity selector + "Add to cart". Disabled when out of stock.
class AddToCartBar extends StatefulWidget {
  const AddToCartBar({required this.product, super.key});

  final Product product;

  @override
  State<AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends State<AddToCartBar> {
  int _quantity = 1;

  void _add(int inCart) {
    final product = widget.product;
    final available = product.stock - inCart;
    final qty = _quantity.clamp(1, available < 1 ? 1 : available);
    context.read<CartBloc>().add(CartItemAdded(product.toCartItem(qty)));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Added $qty × ${product.title} to your cart'),
          duration: const Duration(seconds: 2),
        ),
      );
    setState(() => _quantity = 1);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final inCart = context.select<CartBloc, int>(
      (b) => b.state.quantityOf(product.id),
    );
    final remaining = product.stock - inCart;
    final canAdd = product.isInStock && remaining > 0;

    return Row(
      children: [
        QuantityStepper(
          quantity: canAdd ? _quantity.clamp(1, remaining) : 0,
          min: 1,
          max: canAdd ? remaining : 0,
          enabled: canAdd,
          onChanged: (q) => setState(() => _quantity = q),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: FilledButton.icon(
            onPressed: canAdd ? () => _add(inCart) : null,
            icon: Icon(
              canAdd
                  ? Icons.add_shopping_cart_rounded
                  : Icons.remove_shopping_cart_outlined,
            ),
            label: Text(
              !product.isInStock
                  ? 'Out of stock'
                  : canAdd
                  ? (inCart > 0 ? 'Add more ($inCart in cart)' : 'Add to cart')
                  : 'Max quantity in cart',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
