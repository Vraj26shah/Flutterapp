import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';
import 'package:shopsphere/features/cart/domain/usecases/cart_usecases.dart';

// ---------------------------------------------------------------- events
sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Restores the persisted cart on app start.
final class CartStarted extends CartEvent {
  const CartStarted();
}

final class CartItemAdded extends CartEvent {
  const CartItemAdded(this.item);

  /// [CartItem.quantity] is the amount to add.
  final CartItem item;

  @override
  List<Object?> get props => [item];
}

final class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.productId);

  final int productId;

  @override
  List<Object?> get props => [productId];
}

final class CartQuantityChanged extends CartEvent {
  const CartQuantityChanged(this.productId, this.quantity);

  final int productId;
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

final class CartCleared extends CartEvent {
  const CartCleared();
}

final class CartCheckoutRequested extends CartEvent {
  const CartCheckoutRequested();
}

/// Resets the checkout status after the success screen / error was shown.
final class CartCheckoutAcknowledged extends CartEvent {
  const CartCheckoutAcknowledged();
}

// ----------------------------------------------------------------- state
enum CheckoutStatus { idle, submitting, success, failure }

final class CartState extends Equatable {
  const CartState({
    this.items = const [],
    this.totals = const CartTotals.empty(),
    this.isLoaded = false,
    this.checkoutStatus = CheckoutStatus.idle,
    this.order,
    this.lastOrderTotal = 0,
    this.failure,
  });

  final List<CartItem> items;
  final CartTotals totals;
  final bool isLoaded;
  final CheckoutStatus checkoutStatus;
  final OrderConfirmation? order;

  /// Grand total the user saw when placing the last order. DummyJSON rounds
  /// its own `discountedTotal`, so we show the client-side figure.
  final double lastOrderTotal;
  final Failure? failure;

  bool get isEmpty => items.isEmpty;

  int quantityOf(int productId) => items
      .where((i) => i.productId == productId)
      .fold(0, (sum, i) => sum + i.quantity);

  CartState copyWith({
    List<CartItem>? items,
    CartTotals? totals,
    bool? isLoaded,
    CheckoutStatus? checkoutStatus,
    OrderConfirmation? Function()? order,
    double? lastOrderTotal,
    Failure? Function()? failure,
  }) => CartState(
    items: items ?? this.items,
    totals: totals ?? this.totals,
    isLoaded: isLoaded ?? this.isLoaded,
    checkoutStatus: checkoutStatus ?? this.checkoutStatus,
    order: order != null ? order() : this.order,
    lastOrderTotal: lastOrderTotal ?? this.lastOrderTotal,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    items,
    totals,
    isLoaded,
    checkoutStatus,
    order,
    lastOrderTotal,
    failure,
  ];
}

// ------------------------------------------------------------------ bloc
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({
    required this._loadCart,
    required this._saveCart,
    required this._placeOrder,
    this._calculateTotals = const CalculateCartTotals(),
  }) : super(const CartState()) {
    on<CartStarted>(_onStarted);
    on<CartItemAdded>(_onAdded);
    on<CartItemRemoved>(
      (e, emit) => _update(
        emit,
        state.items.where((i) => i.productId != e.productId).toList(),
      ),
    );
    on<CartQuantityChanged>(_onQuantityChanged);
    on<CartCleared>((_, emit) => _update(emit, const []));
    on<CartCheckoutRequested>(_onCheckout);
    on<CartCheckoutAcknowledged>(
      (_, emit) => emit(
        state.copyWith(
          checkoutStatus: CheckoutStatus.idle,
          order: () => null,
          failure: () => null,
        ),
      ),
    );
  }

  final LoadCartUseCase _loadCart;
  final SaveCartUseCase _saveCart;
  final PlaceOrderUseCase _placeOrder;
  final CalculateCartTotals _calculateTotals;

  Future<void> _onStarted(CartStarted event, Emitter<CartState> emit) async {
    final result = await _loadCart(const NoParams());
    final items = result.fold((_) => const <CartItem>[], (data) => data);
    emit(
      state.copyWith(
        items: items,
        totals: _calculateTotals(items),
        isLoaded: true,
      ),
    );
  }

  Future<void> _onAdded(CartItemAdded event, Emitter<CartState> emit) async {
    final incoming = event.item;
    if (incoming.quantity <= 0 || incoming.stock <= 0) return;
    final items = [...state.items];
    final index = items.indexWhere((i) => i.productId == incoming.productId);
    if (index == -1) {
      items.add(
        incoming.copyWith(quantity: incoming.quantity.clamp(1, incoming.stock)),
      );
    } else {
      final existing = items[index];
      items[index] = existing.copyWith(
        quantity: (existing.quantity + incoming.quantity).clamp(
          1,
          existing.stock,
        ),
      );
    }
    await _update(emit, items);
  }

  Future<void> _onQuantityChanged(
    CartQuantityChanged event,
    Emitter<CartState> emit,
  ) async {
    if (event.quantity <= 0) {
      return _update(
        emit,
        state.items.where((i) => i.productId != event.productId).toList(),
      );
    }
    final items = [
      for (final i in state.items)
        if (i.productId == event.productId)
          i.copyWith(quantity: event.quantity.clamp(1, i.stock))
        else
          i,
    ];
    await _update(emit, items);
  }

  Future<void> _onCheckout(
    CartCheckoutRequested event,
    Emitter<CartState> emit,
  ) async {
    if (state.checkoutStatus == CheckoutStatus.submitting) return;
    emit(
      state.copyWith(
        checkoutStatus: CheckoutStatus.submitting,
        failure: () => null,
      ),
    );
    final result = await _placeOrder(state.items);
    switch (result) {
      case Ok(:final data):
        await _saveCart(const []);
        emit(
          state.copyWith(
            items: const [],
            totals: const CartTotals.empty(),
            checkoutStatus: CheckoutStatus.success,
            order: () => data,
            lastOrderTotal: state.totals.total,
          ),
        );
      case Err(:final failure):
        emit(
          state.copyWith(
            checkoutStatus: CheckoutStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  /// Emits the new items with recalculated totals and persists them.
  Future<void> _update(Emitter<CartState> emit, List<CartItem> items) async {
    emit(state.copyWith(items: items, totals: _calculateTotals(items)));
    await _saveCart(items);
  }
}
