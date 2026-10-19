import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/core/theme/theme_cubit.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';
import 'package:shopsphere/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';
import 'package:shopsphere/features/cart/domain/usecases/cart_usecases.dart';
import 'package:shopsphere/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:shopsphere/features/cart/presentation/pages/cart_page.dart';
import 'package:shopsphere/features/cart/presentation/pages/order_success_page.dart';
import 'package:shopsphere/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:shopsphere/features/profile/presentation/pages/profile_page.dart';

import '../helpers/mocks.dart';
import '../helpers/pump.dart';

const _items = [
  CartItem(
    productId: 1,
    title: 'Essence Mascara Lash Princess with a long name',
    thumbnail: '',
    price: 9.99,
    discountPercentage: 10.48,
    quantity: 2,
    stock: 5,
  ),
  CartItem(
    productId: 2,
    title: 'Red Lipstick',
    thumbnail: '',
    price: 12.99,
    discountPercentage: 0,
    quantity: 1,
    stock: 1,
  ),
];

void main() {
  late MockCartBloc cart;

  setUpAll(() => registerFallbackValue(const CartStarted()));

  setUp(() {
    cart = MockCartBloc();
    when(() => cart.state).thenReturn(
      CartState(
        items: _items,
        totals: const CalculateCartTotals()(_items),
        isLoaded: true,
      ),
    );
  });

  Widget cartPage() =>
      BlocProvider<CartBloc>.value(value: cart, child: const CartPage());

  group('CartPage', () {
    for (final entry in allSizes.entries) {
      testWidgets('renders without overflow: ${entry.key} @ 1.3x', (
        tester,
      ) async {
        await pumpAt(tester, cartPage(), size: entry.value, textScale: 1.3);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows subtotal, discount and grand total', (tester) async {
      await pumpAt(tester, cartPage(), size: tabletPortrait);

      // 2×9.99 + 12.99 = 32.97; discount 19.98×10.48% = 2.09
      expect(find.text(r'$32.97'), findsOneWidget);
      expect(find.text(r'−$2.09'), findsOneWidget);
      expect(find.text(r'$30.88'), findsOneWidget);
      expect(find.text('Subtotal (3 items)'), findsOneWidget);
    });

    testWidgets('quantity buttons and Place order dispatch events', (
      tester,
    ) async {
      await pumpAt(tester, cartPage(), size: tabletPortrait);

      await tester.tap(find.byTooltip('Increase quantity').first);
      verify(() => cart.add(const CartQuantityChanged(1, 3))).called(1);

      await tester.tap(find.text('Place order'));
      verify(() => cart.add(const CartCheckoutRequested())).called(1);
    });

    testWidgets('increase is disabled at the stock limit', (tester) async {
      await pumpAt(tester, cartPage(), size: tabletPortrait);

      final plus = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add_rounded).last,
      );
      expect(plus.onPressed, isNull); // item 2: quantity 1, stock 1
    });

    testWidgets('empty cart shows the empty state', (tester) async {
      when(() => cart.state).thenReturn(const CartState(isLoaded: true));
      await pumpAt(tester, cartPage());

      expect(find.text('Your cart is empty'), findsOneWidget);
    });
  });

  testWidgets('OrderSuccessPage shows the order number and total', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const OrderSuccessPage(
        order: OrderConfirmation(
          orderId: 209,
          total: 89.98,
          discountedTotal: 81,
          totalProducts: 1,
          totalQuantity: 2,
        ),
        total: 81.31,
      ),
      scaffold: false,
      textScale: 1.3,
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('#209'), findsOneWidget);
    expect(find.text(r'$81.31'), findsOneWidget);
  });

  group('ProfilePage', () {
    late MockProfileCubit profile;
    late MockAuthBloc auth;
    late ThemeCubit theme;

    setUp(() async {
      profile = MockProfileCubit();
      auth = MockAuthBloc();
      SharedPreferences.setMockInitialValues({});
      theme = ThemeCubit(await SharedPreferences.getInstance());
      when(() => profile.state).thenReturn(
        const ProfileLoaded(
          User(
            id: 1,
            username: 'emilys',
            email: 'emily.johnson@x.dummyjson.com',
            firstName: 'Emily',
            lastName: 'Johnson',
            image: '',
            phone: '+81 965-431-3024',
          ),
        ),
      );
      when(() => auth.state).thenReturn(const AuthState.authenticated());
    });

    Widget page() => MultiBlocProvider(
      providers: [
        BlocProvider<ProfileCubit>.value(value: profile),
        BlocProvider<AuthBloc>.value(value: auth),
        BlocProvider<ThemeCubit>.value(value: theme),
      ],
      child: const ProfilePage(),
    );

    testWidgets('shows the user details at 1.3x on a phone', (tester) async {
      await pumpAt(tester, page(), textScale: 1.3);

      expect(find.text('Emily Johnson'), findsOneWidget);
      expect(find.text('+81 965-431-3024'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('logout asks for confirmation then signs out', (tester) async {
      await pumpAt(tester, page(), size: tabletPortrait);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
      verify(() => auth.add(const AuthLogoutRequested())).called(1);
    });
  });
}
